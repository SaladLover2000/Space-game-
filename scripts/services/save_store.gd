class_name OrbitSaveStore
extends RefCounted
## Implements one domain; Game owns state and public signals.
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary or value.get("version", 0) != game.VERSION:
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
	game.state = game.defaults()
	game.active = {}
	for path in [game.save_path, game.save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not game.valid_snapshot(parsed):
			game.last_error = "Save was unreadable; checking the backup."
			continue
		game.state.merge(parsed, true)
		if not game.safe_decal_path(game.state.custom_decal):
			game.state.custom_decal = ""
			if game.state.graffiti == "custom": game.state.graffiti = "none"
		var assemblies: Dictionary = game.defaults().engine_modules
		assemblies.merge(game.state.engine_modules,true)
		for key in assemblies: assemblies[key] = int(assemblies[key])
		game.state.engine_modules = assemblies
		if not parsed.has("robot_part_condition"):
			for id in game.state.owned:
				var module: Dictionary = game.part_by_id(id)
				if not module.is_empty() and module.slot.begins_with("robot_") and module.slot != "robot_paint": game.state.robot_part_condition[id] = 100

		game.state.battery = clampi(int(game.state.battery), 0, 100)
		if not parsed.has("engine_condition"):
			game.state.engine_condition = 100 if "engine" in game.state.owned else 0
		var equipment: Dictionary = game.default_equipment()
		for slot in game.state.get("equipped", {}):
			var id: String = game.state.equipped[slot]
			var item: Dictionary = game.part_by_id(id)
			if equipment.has(slot) and not item.is_empty() and item.slot == slot and game.part_owned(id):
				equipment[slot] = id
		game.state.equipped = equipment
		game.state.expansions = game.state.expansions.filter(func(id): return not game.catalog_item(game.expansion_catalog,id).is_empty())
		game.state.research = game.state.research.filter(func(id): return not game.catalog_item(game.research_catalog,id).is_empty())
		# Closed time never earns rewards. Resume a checkpoint paused.
		var saved: Variant = game.state.get("session", {})
		if saved is Dictionary and saved.get("id") is String and (saved.get("minutes") is float or saved.get("minutes") is int) and (saved.get("remaining_ms") is float or saved.get("remaining_ms") is int):
			var mins := int(saved.minutes)
			if mins >= 1 and mins <= 240 and saved.remaining_ms > 0 and saved.remaining_ms <= mins * 60000:
				game.active = saved.duplicate(true)
				game.active.paused = true
		if path.ends_with(".bak"):
			game.last_error = "Recovered your progress from the backup."
		return

func save_progress() -> bool:
	var snapshot: Dictionary = preload("res://scripts/save_data.gd").snapshot(game.state,game.active)
	var file := FileAccess.open(game.save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return game.fail_save()
	file.store_string(JSON.stringify(snapshot))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return game.fail_save()
	# Copy only validated previous snapshots, preserving a healthy backup.
	if FileAccess.file_exists(game.save_path):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
		if game.valid_snapshot(previous):
			if DirAccess.copy_absolute(game.save_path, game.save_path + ".bak") != OK:
				return game.fail_save()
	if DirAccess.rename_absolute(game.save_path + ".tmp", game.save_path) != OK:
		return game.fail_save()
	if not game.last_error.is_empty():
		var previous_error: String = game.last_error
		game.last_error = ""
		game.storage_recovered.emit(previous_error)
	game.cleanup_decals()
	return true

func fail_save() -> bool:
	game.last_error = "Could not save progress. Check disk space and permissions."
	game.storage_error.emit(game.last_error)
	return false

func safe_decal_path(path: String) -> bool:
	return path.is_empty() or (path.begins_with("user://decals/") and path == path.simplify_path() and path.get_extension().to_lower() == "png" and path.get_file().begins_with("art_"))

func cleanup_decals() -> void:
	# Both the current snapshot and recovery backup own their referenced artwork.
	var retained: Array = [game.state.custom_decal]
	if FileAccess.file_exists(game.save_path+".bak"):
		var backup: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.save_path+".bak"))
		if backup is Dictionary: retained.append(backup.get("custom_decal",""))
	var directory := DirAccess.open("user://decals")
	if directory == null: return
	for filename in directory.get_files():
		var path := "user://decals/"+filename
		if game.safe_decal_path(path) and path not in retained:
			DirAccess.remove_absolute(path)

