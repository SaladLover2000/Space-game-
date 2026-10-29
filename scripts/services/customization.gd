class_name OrbitCustomization
extends RefCounted
## Implements one domain; Game owns state and public signals.
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func set_graffiti(design: String, callsign: String) -> bool:
	if design not in ["none","orbit","comet","constellation"]: return false
	var before: Dictionary = game.state.duplicate(true)
	game.state.graffiti = design
	game.state.callsign = callsign.strip_edges().to_upper().left(12)
	return game.commit_or_rollback(before)

func import_decal(path: String) -> Dictionary:
	if path.get_extension().to_lower() != "png" or not FileAccess.file_exists(path): return {"ok":false,"message":"Choose a local PNG image."}
	var image := Image.load_from_file(path)
	if image == null or image.is_empty() or image.get_width() > 2048 or image.get_height() > 2048: return {"ok":false,"message":"Choose a PNG image no larger than 2048 pixels per side."}
	var directory := ProjectSettings.globalize_path("user://decals")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return {"ok":false,"message":"Could not create the local decal folder."}
	var destination := "user://decals/art_%s.png" % Time.get_ticks_usec()
	if image.save_png(destination) != OK: return {"ok":false,"message":"Could not save the imported artwork."}
	var before: Dictionary = game.state.duplicate(true)
	game.state.custom_decal = destination
	game.state.graffiti = "custom"
	if not game.commit_or_rollback(before):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
		return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Personal artwork imported locally."}

func mount_sensor(mount: String, id: String) -> Dictionary:
	if mount not in ["fore","dorsal","aft"]: return {"ok":false,"message":"Unknown sensor hardpoint."}
	if id not in ["antenna_dish","antenna_sensor","antenna_radar"] or not game.part_owned(id): return {"ok":false,"message":"Purchase the sensor before mounting it."}
	if id == "antenna_sensor" and mount == "aft": return {"ok":false,"message":"Docking LiDAR needs a forward or dorsal approach sightline."}
	var before: Dictionary = game.state.duplicate(true)
	game.state.sensor_mounts_configured = true
	for existing in game.state.sensor_mounts.keys():
		if game.state.sensor_mounts[existing] == id: game.state.sensor_mounts.erase(existing)
	game.state.sensor_mounts[mount] = id
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Sensor installed at the "+mount+" hardpoint."}

func unmount_sensor(mount: String) -> bool:
	var before: Dictionary = game.state.duplicate(true)
	game.state.sensor_mounts_configured = true
	game.state.sensor_mounts.erase(mount)
	return game.commit_or_rollback(before)

func effective_sensor_mounts() -> Dictionary:
	if game.state.get("sensor_mounts_configured",false): return game.state.sensor_mounts.duplicate()
	var id: String = game.state.equipped.antenna
	return {"dorsal":id} if id in ["antenna_dish","antenna_sensor","antenna_radar"] else {}
func has_docking_sensor() -> bool:
	var mounts: Dictionary = game.effective_sensor_mounts()
	for mount in mounts:
		if mounts[mount] == "antenna_radar" or (mount in ["fore","dorsal"] and mounts[mount] == "antenna_sensor"): return true
	return false

