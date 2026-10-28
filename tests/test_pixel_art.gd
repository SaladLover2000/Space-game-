extends SceneTree
var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var art := preload("res://assets/pixel_ship_art.gd").new()
	for texture in [art.RESTORED, art.DAMAGED, art.EXTERIOR]:
		var image: Image = texture.get_image()
		check(image.get_size() == Vector2i(1536,1024), "sprite state has the calibrated 1536x1024 atlas size")
		check(image.get_pixel(0,0).a < 0.01 and image.get_pixel(768,500).a > 0.8, "sprite has transparent empty space and visible cabin material")
	check(art.texture_for_room("engine",[]) == art.DAMAGED, "unrepaired reactor uses the damaged raster state")
	check(art.texture_for_room("engine",["engine"]) == art.RESTORED and art.texture_for_room("cockpit",["engine"]) == art.DAMAGED, "repair switches only the purchased room to restored artwork")
	var restored: Image = art.RESTORED.get_image()
	var damaged: Image = art.DAMAGED.get_image()
	check(restored.get_pixel(1120,520) != damaged.get_pixel(1120,520), "reactor artwork differs between damaged and restored states")
	var floor_point: Rect2 = art.source_to_world(Rect2(590,638,1,1))
	check(absf(floor_point.position.y - 103.0) < 1.0, "raster deck aligns with the companion feet baseline")
	check(absf(floor_point.position.x - 95.0) < 1.0 and absf(art.source_to_world(Rect2(945,638,1,1)).position.x - 172.0) < 1.0, "raster room divisions align with both real blocking hatches")
	var view: Control = load("res://assets/ship_view.gd").new()
	root.add_child(view)
	check(view.camera.encloses(art.SPRITE_RECT), "default fitted camera contains the full sprite and both wings")
	check(view.smoke_particle(0,0,0).position == Vector2(294,66) and view.smoke_particle(0,0,1).position == Vector2(294,100), "white exhaust originates at the new aft nozzle positions")
	view.queue_free()
	await process_frame
	print("PIXEL ART RESULT: ", failures, " failures; atlas and state checks do not replace a rendered game review")
	quit(0 if failures == 0 else 1)
