extends SceneTree

var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func click(view: Control, world_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = view.view_transform() * world_position
	view._gui_input(event)
	event.pressed = false
	view._gui_input(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://interior_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("interior")
	await process_frame
	var view: Control = scene.ship_view
	await capture("interior-damaged")
	for id in ["cockpit", "quarters", "engine"]:
		scene.select_room(id)
		await create_timer(0.55).timeout
		for index in range(3):
			click(view, view.object_bounds(id, index).get_center())
			check(view.selected_object == index and scene.inspection_label.text == view.rooms[id].damaged_objects[index], "in-room fixture click inspects %s object %d" % [id, index])
	scene.select_room("")
	await create_timer(0.55).timeout
	var before: Dictionary = game.state.duplicate(true)
	click(view, Vector2(95, 87))
	check(not view.door_open.bridge, "bridge hatch click closes the correct door")
	await create_timer(0.4).timeout
	check(view.door_progress.bridge == 0.0 and view.door_open.engine, "bridge shutter finishes closing without closing engine hatch")
	view.toggle_door("bridge")
	await create_timer(0.4).timeout
	check(view.door_progress.bridge == 1.0, "bridge shutter reopens")
	view.toggle_door("engine")
	view.toggle_door("engine")
	await create_timer(0.4).timeout
	check(view.door_progress.engine == 1.0, "rapid hatch reversal finishes at requested open state")
	check(game.state == before, "interior inspection and door controls change no saved progress")
	game.start_session(25)
	var session_id: String = game.active.id
	view.toggle_door("engine")
	scene.select_room("quarters")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == session_id and game.active.remaining_ms == 1440000, "hatch and inspection actions preserve elapsed study time")
	game.state.credits = 150
	for id in ["cockpit", "quarters", "engine"]:
		game.purchase(id)
	scene.select_room("cockpit")
	await create_timer(0.55).timeout
	click(view, view.object_bounds("cockpit",0).get_center())
	check(scene.inspection_label.text == view.rooms.cockpit.restored_objects[0], "restored equipment click shows restored description")
	scene.select_room("")
	await create_timer(0.55).timeout
	await capture("interior-restored")
	scene.select_room("quarters")
	await create_timer(0.55).timeout
	await capture("quarters-closeup")
	game.cancel_session()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	print("INTERIOR RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
