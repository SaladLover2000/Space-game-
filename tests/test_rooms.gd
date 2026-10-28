extends SceneTree

var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

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
	game.save_path = "user://room_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.focus_task = "Test focus task"
	game.state.started = true
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	await process_frame
	await process_frame
	var view: Control = scene.ship_view
	check(view.expression() == "sad", "low battery companion starts sad")
	check(view.room_at(Vector2(-10, -10)).is_empty(), "outside canvas is not a room")
	for id in ["cockpit", "quarters", "engine"]:
		var hit_position: Vector2 = view.view_transform() * view.room_bounds(id).get_center()
		check(view.room_at(hit_position) == id, "overview hit test for " + id)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = hit_position
		view._gui_input(click)
		click.pressed = false
		view._gui_input(click)
		check(scene.selected_room == id, "room click selects " + id)
		await create_timer(0.55).timeout
		check(view.camera.size.is_equal_approx(Vector2(420, 240)), "room selection keeps the whole ship visible for " + id)
		var zoomed_position: Vector2 = view.view_transform() * view.room_bounds(id).get_center()
		check(view.room_at(zoomed_position) == id, "zoomed hit test for " + id)
		# Inspect the first object through its actual button callback.
		scene.room_panel.get_child(4).pressed.emit()
		check(scene.room_panel.get_child(3).text == view.rooms[id].damaged_objects[0], "object inspection for " + id)
		view.focus_room("")
		await create_timer(0.55).timeout
		check(view.camera == Rect2(-70, -45, 420, 240), "overview returns after " + id)
	scene.select_room("")
	await create_timer(0.55).timeout
	await capture("prototype")
	game.start_session(25)
	var session_id: String = game.active.id
	check(view.expression() == "charging", "running study animates charging dock")
	game.toggle_pause()
	check(view.expression() == "sad", "paused session stops charging animation")
	game.toggle_pause()
	var remaining_before: int = game.active.remaining_ms
	for id in ["cockpit", "engine", "quarters", "engine"]:
		scene.select_room(id)
	await create_timer(0.55).timeout
	check(view.selected_room == "engine" and view.camera.size == Vector2(420, 240), "rapid navigation finishes at the last requested room")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == session_id and game.active.remaining_ms == remaining_before - 60000, "room navigation leaves study session and elapsed timing intact")
	var credit_before: int = game.state.credits
	scene.purchase_room()
	check(game.state.credits == credit_before and game.state.owned.is_empty(), "room repair rejects insufficient funds")
	game.state.credits = 150
	for id in ["engine", "cockpit", "quarters"]:
		scene.select_room(id)
		scene.purchase_room()
		check(id in game.state.owned, "room purchase owns " + id)
	check(game.state.credits == 0, "all three catalog repairs spend exactly 150 credits")
	check(view.expression() == "upgraded", "repair emits companion reaction")
	game.save_progress()
	game.load_progress()
	scene.refresh()
	check(game.state.owned.size() == 3 and game.active.paused, "all room repairs survive reload alongside paused study checkpoint")
	scene.select_room("engine")
	await create_timer(0.55).timeout
	scene.content.get_parent().scroll_vertical = 10000
	await process_frame
	await capture("engine-restored")
	root.size = Vector2i(920, 680)
	root.content_scale_size = Vector2i(920, 680)
	await process_frame
	await process_frame
	check(scene.content.size.x <= 888, "room layout fits minimum window width")
	await capture("minimum-window")
	root.size = Vector2i(1152, 768)
	root.content_scale_size = Vector2i(1152, 768)
	game.active.remaining_ms = 0
	game.finish_session()
	check(view.expression() == "happy", "completed session starts celebration")
	view.reaction_left = 0
	check(view.expression() == "idle", "celebration ends in recharged idle expression")
	scene.show_page("robot")
	await process_frame
	check(is_instance_valid(scene.workshop) and scene.workshop.selected_slot == "robot_shell", "robot tab opens the robot upgrade workshop")
	await create_timer(0.55).timeout
	await capture("robot-status")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.sound_player.stop()
	scene.sound_player.stream = null
	await create_timer(0.1).timeout
	scene.queue_free()
	await process_frame
	print("ROOM RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
