extends Node
## Authoritative state. UI never grants currency or mutates session progress.
signal changed
signal completed(credits: int, xp: int)
signal storage_error(message: String)
signal storage_recovered(previous_message: String)
signal repaired(id: String)

const SAVE_PATH = "user://orbit_v1.json"
const VERSION = 1
var save_store := preload("res://scripts/services/save_store.gd").new(self)
var shop := preload("res://scripts/services/shop.gd").new(self)
var flight := preload("res://scripts/services/flight.gd").new(self)
var docking := preload("res://scripts/services/docking.gd").new(self)
var robot_care := preload("res://scripts/services/robot_care.gd").new(self)
var customization := preload("res://scripts/services/customization.gd").new(self)
var balance: Dictionary
var state: Dictionary
var active: Dictionary = {}
var last_tick: int = 0
var checkpoint: float = 0.0
var save_path: String = SAVE_PATH
var last_error: String = ""
var data_error: String = ""
var engine_modules: Array = []
var parts: Array = []
var parts_index: Dictionary = {}
var effects_outfit: Dictionary = {}
var effects_cache: Dictionary = {}
var expansion_catalog: Array = []
var research_catalog: Array = []
var asteroid_events: Array = []
var encounter_clock: float = 0.0
var field_repair_clock: float = 0.0
var encounter_rng := RandomNumberGenerator.new()

func default_equipment() -> Dictionary:
	return {"engine":"engine_stock", "hull":"hull_stock", "wings":"wings_stock", "paint":"paint_stock", "antenna":"antenna_stock", "lights":"lights_stock", "interior":"interior_stock", "robot_shell":"robot_shell_stock", "robot_visor":"robot_visor_stock", "robot_arms":"robot_arms_stock", "robot_legs":"robot_legs_stock", "robot_core":"robot_core_stock", "robot_paint":"robot_paint_stock"}

func defaults() -> Dictionary:
	return {"version": VERSION, "started": false, "robot": "Pip", "ship": "Little Orbit", "credits": 0, "xp": 0, "battery": 8, "owned": [], "history": [], "total_seconds": 0, "sound": true, "equipped": default_equipment(), "engine_condition": 0, "expansions": [], "research": [], "focus_task": "", "hull_integrity": 100, "cruise_seconds": 0.0, "calm_lights": true, "quarters_decor":[], "sensor_mounts_configured":false, "sensor_mounts":{}, "robot_light":"cyan", "robot_condition":25, "robot_part_condition":{}, "engine_modules":{"pump":0,"injector":0,"cooling":0,"nozzle":0}, "flight_mode":"coast", "docked_station":"", "station_visits":0, "graffiti":"none", "callsign":"", "custom_decal":""}

func _ready() -> void:
	encounter_rng.randomize()
	var catalog := preload("res://scripts/services/catalog_loader.gd").new()
	var loaded: Dictionary = catalog.load_all()
	if loaded.is_empty():
		state = defaults()
		data_error = catalog.error_message
		last_error = data_error
		storage_error.emit(last_error)
		set_process(false)
		return
	balance = loaded.balance
	engine_modules = loaded.engine_modules
	parts = loaded.ship_parts
	expansion_catalog = loaded.expansions
	research_catalog = loaded.research
	for item in parts: parts_index[item.id] = item
	load_progress()
	last_tick = Time.get_ticks_msec()

func _process(delta: float) -> void:
	advance_flight(delta)
	advance(Time.get_ticks_msec())
	checkpoint += delta
	if checkpoint >= 10.0:
		checkpoint = 0
		if not active.is_empty():
			save_progress()

func advance(now: int) -> void:
	var elapsed := maxi(0, now - last_tick)
	last_tick = now
	if active.is_empty() or active.paused:
		return
	active.remaining_ms = maxi(0, int(active.remaining_ms) - elapsed)
	if active.remaining_ms == 0:
		finish_session()

func start_session(minutes: int) -> bool:
	if not active.is_empty() or minutes < 1 or minutes > 240 or state.focus_task.strip_edges().is_empty():
		return false
	active = {"id": str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec()), "minutes": minutes, "remaining_ms": minutes * 60000, "paused": false, "task": state.focus_task.strip_edges().left(160), "effects": equipment_effects()}
	last_tick = Time.get_ticks_msec()
	save_progress()
	changed.emit()
	return true

func toggle_pause() -> void:
	advance(Time.get_ticks_msec())
	if active.is_empty():
		return
	if active.paused and active.get("task","" ).strip_edges().is_empty():
		if state.focus_task.strip_edges().is_empty(): return
		active.task = state.focus_task.strip_edges().left(160)
	active.paused = not active.paused
	save_progress()
	changed.emit()

func cancel_session() -> void:
	active = {}
	save_progress()
	changed.emit()

func finish_session() -> void:
	if active.is_empty() or int(active.remaining_ms) > 0:
		return
	var session := active.duplicate(true)
	active = {} # Consume once before any signal or persistence callback.
	for entry in state.history:
		if entry.id == session.id:
			return
	var minutes := int(session.minutes)
	var credits := minutes * int(balance.credits_per_minute)
	var xp := minutes * int(balance.xp_per_minute)
	xp += floori(xp*float(session.get("effects",{}).get("xp_percent",0))/100.0)
	state.credits += credits
	state.xp += xp
	state.battery = mini(100, int(state.battery) + minutes * int(balance.battery_per_minute) + floori(minutes*int(balance.battery_per_minute)*float(session.get("effects",{}).get("battery_percent",0))/100.0))
	state.total_seconds += minutes * 60
	state.history.append({"id": session.id, "minutes": minutes, "credits": credits, "xp": xp, "task": session.get("task", ""), "date": Time.get_datetime_string_from_system()})
	save_progress() # Reward and consumed session persist in one snapshot.
	changed.emit()
	completed.emit(credits, xp)

func purchase(id: String) -> String:
	return shop.purchase(id)

func part_by_id(id: String) -> Dictionary:
	return shop.part_by_id(id)

func part_owned(id: String) -> bool:
	return shop.part_owned(id)

func part_lock(item: Dictionary) -> String:
	return shop.part_lock(item)

func commit_or_rollback(before: Dictionary) -> bool:
	if save_progress():
		changed.emit()
		return true
	state = before
	changed.emit()
	return false

func buy_part(id: String) -> Dictionary:
	return shop.buy_part(id)

func equip_part(id: String) -> Dictionary:
	return shop.equip_part(id)

func engine_overhaul_price() -> int:
	return shop.engine_overhaul_price()

func service_engine(full: bool = false) -> Dictionary:
	return shop.service_engine(full)

func visual_repairs() -> Array:
	var result: Array = state.owned.duplicate()
	if state.engine_condition >= 25 and "engine" not in result:
		result.append("engine")
	if state.engine_condition < 25:
		result.erase("engine")
	return result

func update_names(robot: String, ship: String, complete_setup: bool = false) -> bool:
	state.robot = robot.strip_edges().left(24) if not robot.strip_edges().is_empty() else "Pip"
	state.ship = ship.strip_edges().left(24) if not ship.strip_edges().is_empty() else "Little Orbit"
	if complete_setup:
		state.started = true
	var saved := save_progress()
	changed.emit()
	return saved

func rename_companions(robot: String, ship: String) -> bool:
	return update_names(robot, ship, true)

func valid_snapshot(value: Variant) -> bool:
	return save_store.valid_snapshot(value)

func load_progress() -> void:
	save_store.load_progress()

func save_progress() -> bool:
	return save_store.save_progress()

func fail_save() -> bool:
	return save_store.fail_save()

func catalog_item(catalog: Array, id: String) -> Dictionary:
	return shop.catalog_item(catalog, id)

func has_unlock(id: String) -> bool:
	return shop.has_unlock(id)

func unlock_requirement(item: Dictionary) -> String:
	return shop.unlock_requirement(item)

func unlock_project(field: String, catalog: Array, id: String) -> Dictionary:
	return shop.unlock_project(field, catalog, id)

func build_expansion(id: String) -> Dictionary:
	return shop.build_expansion(id)

func research_project(id: String) -> Dictionary:
	return shop.research_project(id)

func advance_flight(delta: float) -> void:
	flight.advance_flight(delta)

func resolve_encounter(impact_roll: float, damage_roll: float) -> Dictionary:
	return flight.resolve_encounter(impact_roll, damage_roll)

func apply_contact(event: Dictionary) -> void:
	flight.apply_contact(event)

func patch_hull() -> Dictionary:
	return flight.patch_hull()

func robot_activity() -> String:
	return robot_care.robot_activity()

func equipment_effects(outfit: Dictionary = {}) -> Dictionary:
	return shop.equipment_effects(outfit)

func effect_lines(item: Dictionary) -> Array[String]:
	return shop.effect_lines(item)

func service_robot(full: bool = false) -> Dictionary:
	return robot_care.service_robot(full)

func upgrade_engine_module(id: String) -> Dictionary:
	return shop.upgrade_engine_module(id)

func ship_level() -> int:
	return flight.ship_level()

func flight_lock(mode: String) -> String:
	return flight.flight_lock(mode)

func flight_speed() -> float:
	return flight.flight_speed()

func set_flight_mode(mode: String) -> Dictionary:
	return flight.set_flight_mode(mode)

func station_contact() -> Dictionary:
	return docking.station_contact()

func docking_lock() -> String:
	return docking.docking_lock()

func dock_station() -> Dictionary:
	return docking.dock_station()

func undock_station() -> bool:
	return docking.undock_station()

func set_robot_light(value: String) -> bool:
	return robot_care.set_robot_light(value)

func robot_thought(room: String = "ship", time: float = 0) -> String:
	return robot_care.robot_thought(room, time)

func set_graffiti(design: String, callsign: String) -> bool:
	return customization.set_graffiti(design, callsign)

func import_decal(path: String) -> Dictionary:
	return customization.import_decal(path)

func mount_sensor(mount: String, id: String) -> Dictionary:
	return customization.mount_sensor(mount, id)

func unmount_sensor(mount: String) -> bool:
	return customization.unmount_sensor(mount)

func buy_quarters_decor(id: String) -> Dictionary:
	return shop.buy_quarters_decor(id)

func effective_sensor_mounts() -> Dictionary:
	return customization.effective_sensor_mounts()

func has_docking_sensor() -> bool:
	return customization.has_docking_sensor()

func planet_contact() -> Dictionary:
	return docking.planet_contact()

func landing_lock() -> String:
	return docking.landing_lock()

func land_planet() -> Dictionary:
	return docking.land_planet()

func sync_equipped_sensor(slot: String, id: String) -> void:
	shop.sync_equipped_sensor(slot, id)

func set_setting(key: String, value: bool) -> bool:
	if key not in ["sound","calm_lights"]: return false
	var before := state.duplicate(true)
	state[key] = value
	return commit_or_rollback(before)

func repair_price(id: String) -> int:
	return shop.repair_price(id)

func port_rules(kind: String) -> Dictionary:
	return docking.port_rules(kind)

func safe_decal_path(path: String) -> bool:
	return save_store.safe_decal_path(path)

func cleanup_decals() -> void:
	save_store.cleanup_decals()

func set_focus_task(value: String) -> bool:
	var text := value.strip_edges().left(160)
	if text == state.focus_task: return true
	var before := state.duplicate(true)
	state.focus_task = text
	return commit_or_rollback(before)
