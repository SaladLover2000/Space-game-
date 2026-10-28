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
var parts: Array = []

func default_equipment() -> Dictionary:
	return {"engine":"engine_stock", "hull":"hull_stock", "wings":"wings_stock", "paint":"paint_stock", "antenna":"antenna_stock", "lights":"lights_stock", "interior":"interior_stock", "robot_shell":"robot_shell_stock", "robot_visor":"robot_visor_stock", "robot_arms":"robot_arms_stock", "robot_legs":"robot_legs_stock", "robot_core":"robot_core_stock"}

func defaults() -> Dictionary:
	return {"version": VERSION, "started": false, "robot": "Pip", "ship": "Little Orbit", "credits": 0, "xp": 0, "battery": 8, "owned": [], "history": [], "total_seconds": 0, "sound": true, "equipped": default_equipment(), "engine_condition": 0}

func _ready() -> void:
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	parts = JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_parts.json"))
	load_progress()
	last_tick = Time.get_ticks_msec()

func _process(delta: float) -> void:
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
	if not active.is_empty() or minutes < 1 or minutes > 240:
		return false
	active = {"id": str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec()), "minutes": minutes, "remaining_ms": minutes * 60000, "paused": false}
	last_tick = Time.get_ticks_msec()
	save_progress()
	changed.emit()
	return true

func toggle_pause() -> void:
	advance(Time.get_ticks_msec())
	if active.is_empty():
		return
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
	state.credits += credits
	state.xp += xp
	state.battery = mini(100, int(state.battery) + minutes * int(balance.battery_per_minute))
	state.total_seconds += minutes * 60
	state.history.append({"id": session.id, "minutes": minutes, "credits": credits, "xp": xp, "date": Time.get_datetime_string_from_system()})
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
			return "Keep studying — you need %d more credits." % (item.price - state.credits)
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
	state.equipped[item.slot] = id
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
	for key in ["credits", "xp", "battery", "total_seconds"]:
		if value.has(key) and (not (value[key] is float or value[key] is int) or value[key] < 0 or value[key] > 1000000000):
			return false
	for key in ["robot", "ship"]:
		if value.has(key) and not value[key] is String:
			return false
	for key in ["started", "sound"]:
		if value.has(key) and not value[key] is bool:
			return false
	for key in ["owned", "history"]:
		if value.has(key) and not value[key] is Array:
			return false
	if value.has("engine_condition") and (not (value.engine_condition is float or value.engine_condition is int) or value.engine_condition < 0 or value.engine_condition > 100):
		return false
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
