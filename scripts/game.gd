extends Node
## Authoritative state. UI never grants currency or mutates session progress.
signal changed
signal completed(credits: int, xp: int)
signal storage_error(message: String)
signal storage_recovered(previous_message: String)
signal repaired(id: String)

const SAVE_PATH = "user://orbit_v1.json"
const VERSION = 1
var balance: Dictionary
var state: Dictionary
var active: Dictionary = {}
var last_tick: int = 0
var checkpoint: float = 0.0
var save_path: String = SAVE_PATH
var last_error: String = ""
var engine_modules: Array = []
var parts: Array = []
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
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	engine_modules = JSON.parse_string(FileAccess.get_file_as_string("res://data/engine_modules.json"))
	parts = JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_parts.json"))
	expansion_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/expansions.json"))
	research_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/research.json"))
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
	for item in balance.repairs:
		if item.id != id:
			continue
		if id in state.owned:
			return "Already restored."
		if state.xp < item.xp:
			return "More research is needed."
		if state.credits < item.price:
			return "Keep studying - you need %d more credits." % (item.price - state.credits)
		state.credits -= int(item.price)
		state.owned.append(id)
		if id == "engine":
			state.engine_condition = 100
		save_progress()
		changed.emit()
		repaired.emit(id)
		return "%s complete. A little more like home." % item.name
	return "Unknown component."

func part_by_id(id: String) -> Dictionary:
	for item in parts:
		if item.id == id:
			return item
	return {}

func part_owned(id: String) -> bool:
	var item := part_by_id(id)
	return not item.is_empty() and (item.price == 0 or id in state.owned)

func part_lock(item: Dictionary) -> String:
	if item.is_empty():
		return "Unknown part."
	if state.xp < item.xp:
		return "Requires %d research XP; you have %d." % [item.xp, state.xp]
	if item.has("requires") and item.requires not in state.owned:
		return "Complete the engine overhaul before fitting this engine."
	return ""

func commit_purchase(before: Dictionary) -> bool:
	if save_progress():
		changed.emit()
		return true
	state = before
	changed.emit()
	return false

func buy_part(id: String) -> Dictionary:
	var item := part_by_id(id)
	if item.is_empty():
		return {"ok": false, "message": "Unknown part."}
	if part_owned(id):
		return equip_part(id)
	var lock := part_lock(item)
	if not lock.is_empty():
		return {"ok": false, "message": lock}
	if state.credits < item.price:
		return {"ok": false, "message": "Need %d more credits." % (item.price - state.credits)}
	var before := state.duplicate(true)
	state.credits -= int(item.price)
	state.owned.append(id)
	if item.slot.begins_with("robot_") and item.slot != "robot_paint":
		state.robot_condition = mini(100,int(state.robot_condition)+5)
		state.robot_part_condition[id] = 100
	state.equipped[item.slot] = id
	if item.slot == "antenna":
		state.sensor_mounts_configured = true
		if id == "antenna_stock": state.sensor_mounts.erase("dorsal")
		else: state.sensor_mounts.dorsal = id
	if not commit_purchase(before):
		return {"ok": false, "message": last_error}
	repaired.emit(id)
	return {"ok": true, "message": item.name + " purchased and equipped."}

func equip_part(id: String) -> Dictionary:
	var item := part_by_id(id)
	if item.is_empty() or not part_owned(id):
		return {"ok": false, "message": "Buy this part before equipping it."}
	if state.equipped.get(item.slot) == id:
		return {"ok": true, "message": "Already equipped."}
	var before := state.duplicate(true)
	state.equipped[item.slot] = id
	if item.slot == "antenna":
		state.sensor_mounts_configured = true
		if id == "antenna_stock": state.sensor_mounts.erase("dorsal")
		else: state.sensor_mounts.dorsal = id
	if not commit_purchase(before):
		return {"ok": false, "message": last_error}
	return {"ok": true, "message": item.name + " equipped. No charge."}

func engine_overhaul_price() -> int:
	for item in balance.repairs:
		if item.id == "engine":
			return int(item.price)
	return 50

func service_engine(full: bool = false) -> Dictionary:
	if state.engine_condition >= 100 and (not full or "engine" in state.owned):
		return {"ok": false, "message": "Engine is already in full condition."}
	var price := engine_overhaul_price() if full else int(balance.engine_patch_price)
	if state.credits < price:
		return {"ok": false, "message": "Need %d more credits for this repair." % (price - state.credits)}
	var before := state.duplicate(true)
	state.credits -= price
	state.engine_condition = 100 if full else mini(100, int(state.engine_condition) + int(balance.engine_patch_points))
	if full and "engine" not in state.owned:
		state.owned.append("engine")
	if not commit_purchase(before):
		return {"ok": false, "message": last_error}
	repaired.emit("engine")
	return {"ok": true, "message": "Engine overhauled." if full else "Engine patched: %d%% condition. A full overhaul unlocks replacement engines." % state.engine_condition}

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
	if not value is Dictionary or value.get("version", 0) != VERSION:
		return false
	for key in ["credits", "xp", "battery", "total_seconds", "hull_integrity", "cruise_seconds"]:
		if value.has(key) and (not (value[key] is float or value[key] is int) or value[key] < 0 or value[key] > 1000000000):
			return false
	for key in ["robot", "ship", "focus_task"]:
		if value.has(key) and not value[key] is String:
			return false
	for key in ["started", "sound", "calm_lights"]:
		if value.has(key) and not value[key] is bool:
			return false
	for key in ["owned", "history", "expansions", "research"]:
		if value.has(key) and not value[key] is Array:
			return false
	for field in ["expansions", "research"]:
		for id in value.get(field, []):
			if not id is String:
				return false
	if value.get("hull_integrity",100) > 100:
		return false
	if value.has("engine_condition") and (not (value.engine_condition is float or value.engine_condition is int) or value.engine_condition < 0 or value.engine_condition > 100):
		return false
	if value.has("robot_condition") and (not (value.robot_condition is int or value.robot_condition is float) or value.robot_condition < 0 or value.robot_condition > 100): return false
	if value.has("robot_part_condition"):
		if not value.robot_part_condition is Dictionary: return false
		for id in value.robot_part_condition:
			var condition: Variant = value.robot_part_condition[id]
			if not id is String or not (condition is int or condition is float) or condition < 0 or condition > 100: return false
	if value.has("engine_modules"):
		if not value.engine_modules is Dictionary: return false
		for key in value.engine_modules:
			if key not in ["pump","injector","cooling","nozzle"] or not (value.engine_modules[key] is int or value.engine_modules[key] is float) or value.engine_modules[key] != int(value.engine_modules[key]) or value.engine_modules[key] < 0 or value.engine_modules[key] > 3: return false
	if value.has("flight_mode") and value.flight_mode not in ["coast","cruise","burn"]: return false
	if value.has("station_visits") and (not (value.station_visits is int or value.station_visits is float) or value.station_visits < 0 or value.station_visits != int(value.station_visits)): return false
	for key in ["docked_station","graffiti","callsign","custom_decal"]:
		if value.has(key) and not value[key] is String: return false
	if value.has("quarters_decor"):
		if not value.quarters_decor is Array: return false
		for decoration in value.quarters_decor:
			if decoration not in ["terrarium","tool_rack","relay_project"]: return false
	if value.has("sensor_mounts_configured") and not value.sensor_mounts_configured is bool: return false
	if value.has("sensor_mounts"):
		if not value.sensor_mounts is Dictionary: return false
		for mount in value.sensor_mounts:
			if mount not in ["fore","dorsal","aft"] or value.sensor_mounts[mount] not in ["antenna_dish","antenna_sensor","antenna_radar"]: return false
	if value.has("robot_light") and value.robot_light not in ["cyan","blue","green","violet","white"]: return false
	if value.has("equipped"):
		if not value.equipped is Dictionary:
			return false
		for id in value.equipped.values():
			if not id is String:
				return false
	for entry in value.get("history", []):
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("date") is String or not (entry.get("minutes") is float or entry.get("minutes") is int):
			return false
	return true

func load_progress() -> void:
	state = defaults()
	active = {}
	for path in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not valid_snapshot(parsed):
			last_error = "Save was unreadable; checking the backup."
			continue
		state.merge(parsed, true)
		var assemblies: Dictionary = defaults().engine_modules
		assemblies.merge(state.engine_modules,true)
		for key in assemblies: assemblies[key] = int(assemblies[key])
		state.engine_modules = assemblies
		if not parsed.has("robot_part_condition"):
			for id in state.owned:
				var module := part_by_id(id)
				if not module.is_empty() and module.slot.begins_with("robot_") and module.slot != "robot_paint": state.robot_part_condition[id] = 100

		state.battery = clampi(int(state.battery), 0, 100)
		if not parsed.has("engine_condition"):
			state.engine_condition = 100 if "engine" in state.owned else 0
		var equipment := default_equipment()
		for slot in state.get("equipped", {}):
			var id: String = state.equipped[slot]
			var item := part_by_id(id)
			if equipment.has(slot) and not item.is_empty() and item.slot == slot and part_owned(id):
				equipment[slot] = id
		state.equipped = equipment
		state.expansions = state.expansions.filter(func(id): return not catalog_item(expansion_catalog,id).is_empty())
		state.research = state.research.filter(func(id): return not catalog_item(research_catalog,id).is_empty())
		# Closed time never earns rewards. Resume a checkpoint paused.
		var saved: Variant = state.get("session", {})
		if saved is Dictionary and saved.get("id") is String and (saved.get("minutes") is float or saved.get("minutes") is int) and (saved.get("remaining_ms") is float or saved.get("remaining_ms") is int):
			var mins := int(saved.minutes)
			if mins >= 1 and mins <= 240 and saved.remaining_ms > 0 and saved.remaining_ms <= mins * 60000:
				active = saved.duplicate(true)
				active.paused = true
		if path.ends_with(".bak"):
			last_error = "Recovered your progress from the backup."
		return

func save_progress() -> bool:
	var snapshot := state.duplicate(true)
	snapshot.session = active
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return fail_save()
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return fail_save()
	# Copy only validated previous snapshots, preserving a healthy backup.
	if FileAccess.file_exists(save_path):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if valid_snapshot(previous):
			if DirAccess.copy_absolute(save_path, save_path + ".bak") != OK:
				return fail_save()
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK:
		return fail_save()
	if not last_error.is_empty():
		var previous_error := last_error
		last_error = ""
		storage_recovered.emit(previous_error)
	return true

func fail_save() -> bool:
	last_error = "Could not save progress. Check disk space and permissions."
	storage_error.emit(last_error)
	return false

func catalog_item(catalog: Array, id: String) -> Dictionary:
	for item in catalog:
		if item.id == id:
			return item
	return {}

func has_unlock(id: String) -> bool:
	return id in state.owned or id in state.expansions or id in state.research

func unlock_requirement(item: Dictionary) -> String:
	if item.is_empty():
		return "Unknown project."
	for requirement in item.requires:
		if not has_unlock(requirement):
			var required := catalog_item(expansion_catalog,requirement)
			if required.is_empty():
				required = catalog_item(research_catalog,requirement)
			return "Requires " + (required.name if not required.is_empty() else requirement.capitalize() + " restoration") + "."
	if state.xp < item.xp:
		return "Requires %d accumulated research XP." % item.xp
	return ""

func unlock_project(field: String, catalog: Array, id: String) -> Dictionary:
	var item := catalog_item(catalog,id)
	if item.is_empty():
		return {"ok":false,"message":"Unknown project."}
	if id in state[field]:
		return {"ok":false,"message":"Already completed."}
	var requirement := unlock_requirement(item)
	if not requirement.is_empty():
		return {"ok":false,"message":requirement}
	if state.credits < item.price:
		return {"ok":false,"message":"Need %d more credits." % (item.price-state.credits)}
	var before := state.duplicate(true)
	state.credits -= int(item.price)
	state[field].append(id)
	if not commit_purchase(before):
		return {"ok":false,"message":last_error}
	repaired.emit(id)
	return {"ok":true,"message":item.name + " complete."}

func build_expansion(id: String) -> Dictionary:
	return unlock_project("expansions",expansion_catalog,id)

func research_project(id: String) -> Dictionary:
	return unlock_project("research",research_catalog,id)

func advance_flight(delta: float) -> void:
	if not state.started:
		return
	var elapsed := clampf(delta,0.0,1.0)
	if not state.docked_station.is_empty(): return
	if not flight_lock(state.flight_mode).is_empty(): state.flight_mode = "coast"
	state.cruise_seconds += elapsed*(1.0+equipment_effects().cruise_percent/100.0)*flight_speed()
	for event in asteroid_events:
		event.age += elapsed
		if event.age >= 5.0: apply_contact(event)
	asteroid_events = asteroid_events.filter(func(event): return event.age < 14.0)
	encounter_clock += elapsed
	if encounter_clock >= 100.0:
		encounter_clock = 0
		resolve_encounter(encounter_rng.randf(),encounter_rng.randf())
	if state.hull_integrity < 100 and robot_activity() == "field_repair":
		field_repair_clock += elapsed
		if field_repair_clock >= 30.0/(1.0+equipment_effects().repair_percent/100.0):
			field_repair_clock = 0
			state.hull_integrity = mini(100,int(state.hull_integrity)+1)
			save_progress()
			changed.emit()

func resolve_encounter(impact_roll: float, damage_roll: float) -> Dictionary:
	var impact := impact_roll < 0.25
	var damage := 2 if impact and damage_roll < 0.06 else 0
	var event := {"age":0.0,"impact":impact,"damage":damage,"resolved":false,"lane":81.0 if impact else -20.0+impact_roll*200.0,"radius":2.0+damage_roll*3.0}
	asteroid_events.append(event)
	return event

func apply_contact(event: Dictionary) -> void:
	if event.get("resolved",false): return
	event.resolved = true
	if event.damage > 0:
		var before := state.duplicate(true)
		state.hull_integrity = maxi(80,int(state.hull_integrity)-maxi(0,int(event.damage)-int(equipment_effects().damage_reduction)))
		if not commit_purchase(before): event.damage = 0

func patch_hull() -> Dictionary:
	if state.hull_integrity >= 100: return {"ok":false,"message":"Hull is already sound."}
	if state.credits < 5: return {"ok":false,"message":"Hull patch costs 5 credits. Your robot can also make slow free field repairs."}
	var before := state.duplicate(true)
	state.credits -= 5
	state.hull_integrity = mini(100,int(state.hull_integrity)+10)
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Hull patched."}

func robot_activity() -> String:
	if state.hull_integrity < 100: return "field_repair"
	if not active.is_empty() and not active.paused: return "charging"
	return ["maintenance","resting","sleeping","observing"][int(state.cruise_seconds/40.0)%4]

func equipment_effects(outfit: Dictionary = {}) -> Dictionary:
	var result := {"xp_percent":0,"battery_percent":0,"move_percent":0,"repair_percent":0,"cruise_percent":0,"damage_reduction":0,"work_lamp":0}
	var equipped: Dictionary = state.equipped if outfit.is_empty() else outfit
	for id in equipped.values():
		for key in part_by_id(id).get("effects",{}): result[key] += int(part_by_id(id).effects[key])
	result.xp_percent = mini(15,result.xp_percent)
	result.repair_percent = mini(60,result.repair_percent)
	result.damage_reduction = mini(1,result.damage_reduction)
	return result

func effect_lines(item: Dictionary) -> Array[String]:
	var labels := {"xp_percent":"Research XP +%d%% on completed focus", "battery_percent":"Study battery recharge +%d%%", "move_percent":"Robot walking speed +%d%%", "repair_percent":"Free hull repair rate +%d%%", "cruise_percent":"Cruise scenery speed +%d%%", "damage_reduction":"Rare impact damage -%d hull point", "work_lamp":"Work lamp / illuminates active maintenance"}
	var lines: Array[String] = []
	for key in item.get("effects",{}):
		lines.append(labels[key] if key == "work_lamp" else labels[key] % item.effects[key])
	if lines.is_empty(): lines.append("Appearance only / no stat change" if item.slot in ["robot_paint","paint","lights","interior"] else "Standard hardware / baseline performance")
	return lines

func service_robot(full: bool = false) -> Dictionary:
	if state.robot_condition >= 100: return {"ok":false,"message":"Robot is already serviced."}
	var price := 30 if full else 8
	if state.credits < price: return {"ok":false,"message":"Need %d credits for robot care." % price}
	var before := state.duplicate(true)
	state.credits -= price
	state.robot_condition = mini(100,int(state.robot_condition)+(40 if full else 15))
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Frame repaired and cleaned." if full else "Joints oiled and contacts cleaned."}

func upgrade_engine_module(id: String) -> Dictionary:
	var item := catalog_item(engine_modules,id)
	if item.is_empty(): return {"ok":false,"message":"Unknown engine assembly."}
	if "engine" not in state.owned: return {"ok":false,"message":"Restore the engine before upgrading its assemblies."}
	var tier: int = state.engine_modules.get(id,0)
	if tier >= 3: return {"ok":false,"message":"Assembly already at maximum tier."}
	if state.xp < item.xp[tier]: return {"ok":false,"message":"Requires %d research XP." % item.xp[tier]}
	if state.credits < item.price[tier]: return {"ok":false,"message":"Requires %d credits." % item.price[tier]}
	var before := state.duplicate(true)
	state.credits -= int(item.price[tier])
	state.engine_modules[id] = tier+1
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":item.name+" upgraded to tier %d." % (tier+1)}

func ship_level() -> int:
	var tiers := 0
	for tier in state.engine_modules.values(): tiers += int(tier)
	return mini(5,1+(1 if "engine" in state.owned else 0)+tiers/4+(1 if state.equipped.hull == "hull_shielded" else 0))

func flight_lock(mode: String) -> String:
	if mode == "coast": return ""
	if "engine" not in state.owned or state.engine_condition < 75: return "Restore the engine and reach 75% engine condition."
	if mode == "cruise":
		return "Upgrade turbopump and nozzle to tier 1." if state.engine_modules.pump < 1 or state.engine_modules.nozzle < 1 else ""
	if mode == "burn":
		for tier in state.engine_modules.values():
			if tier < 3: return "Maximum thrust requires all four engine assemblies at tier 3."
		if state.engine_condition < 100 or state.equipped.hull != "hull_shielded": return "Maximum thrust requires full engine condition and ceramic thermal cladding."
		if "navigation_patch" not in state.research: return "Install the navigation software rebuild."
		return ""
	return "Unknown flight mode."

func flight_speed() -> float:
	return 6.0 if state.flight_mode == "burn" else 2.5 if state.flight_mode == "cruise" else 1.0

func set_flight_mode(mode: String) -> Dictionary:
	var lock := flight_lock(mode)
	if not lock.is_empty(): return {"ok":false,"message":lock}
	if not state.docked_station.is_empty(): return {"ok":false,"message":"Undock before engaging propulsion."}
	var before := state.duplicate(true)
	state.flight_mode = mode
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Flight mode: "+mode}

func station_contact() -> Dictionary:
	var phase := fposmod(state.cruise_seconds,240)
	var sensor_range := 130.0 if has_docking_sensor() else 180.0
	if phase < sensor_range: return {}
	return {"id":"station_%d" % (int(state.cruise_seconds/240)%3),"name":["Wayfarer Exchange","Kepler Repair Dock","Aster Research Port"][int(state.cruise_seconds/240)%3],"price":350,"level":3}

func docking_lock() -> String:
	if not state.docked_station.is_empty(): return "Already docked."
	if station_contact().is_empty(): return "No station is currently in sensor range."
	if ship_level() < 3: return "Station approach requires overall ship level 3."
	if not has_docking_sensor(): return "Fit docking LiDAR or rendezvous radar for approach."
	if state.engine_condition < 75 or state.hull_integrity < 90: return "Approach requires engine 75% and hull 90%."
	if state.credits < 350: return "Station docking costs 350 credits."
	return ""

func dock_station() -> Dictionary:
	var lock := docking_lock()
	if not lock.is_empty(): return {"ok":false,"message":lock}
	var before := state.duplicate(true)
	state.credits -= 350
	state.docked_station = station_contact().id
	state.station_visits += 1
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Docking complete. Focus time continues."}

func undock_station() -> void:
	var before := state.duplicate(true)
	state.docked_station = ""
	commit_purchase(before)

func set_robot_light(value: String) -> bool:
	if value not in ["cyan","blue","green","violet","white"]: return false
	var before := state.duplicate(true)
	state.robot_light = value
	return commit_purchase(before)

func robot_thought(room: String = "ship", time: float = 0) -> String:
	var lines: Array = []
	if room == "charging":
		lines = ["Battery topped up. Ready when you are.","Systems rested. Your chosen lights are back."] if state.battery >= 100 else ["Recharge cycle engaged. Good night...","Saving power while you focus...","Wake me after a little more study."]
	elif room == "engine":
		lines = ["Checking the coolant pressure.","This loose coupling needs a careful reseat.","I will sort these spare parts before the next burn.","A better turbopump would help our next cruise."] if state.engine_condition < 75 else ["Pressure steady. Checking the injector seals.","Logging nozzle temperatures.","Putting the tools back, then another inspection."]
	elif room == "cockpit":
		lines = ["Legacy navigation is offline. Tracing the fault.","Testing the next control circuit.","Rebuilding the route table, one line at a time.","Coasting safely while I check the console."] if "navigation_patch" not in state.research else ["Plotting a clear course.","Checking traffic beyond the next planet.","Navigation checks complete. Watching the instruments."]
	elif room == "quarters":
		lines = ["Let me assemble this little relay.","Sorting the spare fasteners.","Testing the workbench power supply.","A tidy bench makes the next repair easier."]
	else:
		lines = ["Another quiet mile between the stars.","I will check the workshop next.","Keeping an eye on the ship while you focus.","There is always a little circuit to mend."]
		if state.battery < 20: lines.append("Low battery... I should visit my charging cradle.")
		if state.robot_condition < 45: lines.append("A little oil would make these joints happier.")
	return lines[int(time/14)%lines.size()]

func set_graffiti(design: String, callsign: String) -> bool:
	if design not in ["none","orbit","comet","constellation"]: return false
	var before := state.duplicate(true)
	state.graffiti = design
	state.callsign = callsign.strip_edges().to_upper().left(12)
	return commit_purchase(before)

func import_decal(path: String) -> Dictionary:
	if path.get_extension().to_lower() != "png" or not FileAccess.file_exists(path): return {"ok":false,"message":"Choose a local PNG image."}
	var image := Image.load_from_file(path)
	if image == null or image.is_empty() or image.get_width() > 2048 or image.get_height() > 2048: return {"ok":false,"message":"Choose a PNG image no larger than 2048 pixels per side."}
	var directory := ProjectSettings.globalize_path("user://decals")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return {"ok":false,"message":"Could not create the local decal folder."}
	var destination := "user://decals/art_%s.png" % Time.get_ticks_usec()
	if image.save_png(destination) != OK: return {"ok":false,"message":"Could not save the imported artwork."}
	var before := state.duplicate(true)
	state.custom_decal = destination
	state.graffiti = "custom"
	if not commit_purchase(before):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
		return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Personal artwork imported locally."}

func mount_sensor(mount: String, id: String) -> Dictionary:
	if mount not in ["fore","dorsal","aft"]: return {"ok":false,"message":"Unknown sensor hardpoint."}
	if id not in ["antenna_dish","antenna_sensor","antenna_radar"] or not part_owned(id): return {"ok":false,"message":"Purchase the sensor before mounting it."}
	if id == "antenna_sensor" and mount == "aft": return {"ok":false,"message":"Docking LiDAR needs a forward or dorsal approach sightline."}
	var before := state.duplicate(true)
	state.sensor_mounts_configured = true
	for existing in state.sensor_mounts.keys():
		if state.sensor_mounts[existing] == id: state.sensor_mounts.erase(existing)
	state.sensor_mounts[mount] = id
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Sensor installed at the "+mount+" hardpoint."}

func unmount_sensor(mount: String) -> bool:
	var before := state.duplicate(true)
	state.sensor_mounts_configured = true
	state.sensor_mounts.erase(mount)
	return commit_purchase(before)

func buy_quarters_decor(id: String) -> Dictionary:
	var prices := {"terrarium":20,"tool_rack":25,"relay_project":30}
	if not prices.has(id): return {"ok":false,"message":"Unknown workshop decoration."}
	if "quarters" not in state.owned: return {"ok":false,"message":"Restore the companion quarters before adding decor."}
	if id in state.quarters_decor: return {"ok":true,"message":"Already installed."}
	if state.credits < prices[id]: return {"ok":false,"message":"More credits needed."}
	var before := state.duplicate(true)
	state.credits -= prices[id]
	state.quarters_decor.append(id)
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Workshop decoration installed."}

func effective_sensor_mounts() -> Dictionary:
	if state.get("sensor_mounts_configured",false): return state.sensor_mounts.duplicate()
	var id: String = state.equipped.antenna
	return {"dorsal":id} if id in ["antenna_dish","antenna_sensor","antenna_radar"] else {}
func has_docking_sensor() -> bool:
	var mounts := effective_sensor_mounts()
	for mount in mounts:
		if mounts[mount] == "antenna_radar" or (mount in ["fore","dorsal"] and mounts[mount] == "antenna_sensor"): return true
	return false

func planet_contact() -> Dictionary:
	for index in range(3):
		var x := fposmod(-150+index*480+state.cruise_seconds*(0.7+index*0.25)+500,1500)-500
		if x >= -70 and x <= 350:
			return {"id":"planet_%d" % index,"index":index,"name":["Copper Reach","Thalassa","Amethyst Moon"][index],"price":500,"level":4}
	return {}
func landing_lock() -> String:
	if not state.docked_station.is_empty(): return "Depart the current port before approaching another destination."
	if planet_contact().is_empty(): return "No planetary port is within approach range."
	if ship_level() < 4: return "Planetary approach requires overall ship level 4."
	if state.engine_condition < 100 or state.hull_integrity < 100: return "Atmospheric approach requires full engine and hull condition."
	if state.equipped.hull != "hull_shielded" or state.engine_modules.cooling < 2: return "Fit ceramic thermal cladding and tier 2 cooling for entry."
	if "navigation_patch" not in state.research or not has_docking_sensor(): return "Install navigation software and an approach sensor."
	if state.credits < 500: return "Planetary port clearance costs 500 credits."
	return ""
func land_planet() -> Dictionary:
	var lock := landing_lock()
	if not lock.is_empty(): return {"ok":false,"message":lock}
	var before := state.duplicate(true)
	state.credits -= 500
	state.docked_station = planet_contact().id
	state.station_visits += 1
	if not commit_purchase(before): return {"ok":false,"message":last_error}
	return {"ok":true,"message":"Planetary port reached. Your focus session continues."}
