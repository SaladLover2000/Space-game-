extends SceneTree

var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func type_name(field: LineEdit, value: String) -> void:
	field.text = value
	field.text_changed.emit(value)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://usability_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.focus_task = "Test focus task"
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1600 and ProjectSettings.get_setting("display/window/size/viewport_height") == 900, "larger 1600x900 design viewport configured")
	check(ProjectSettings.get_setting("display/window/size/mode") == Window.MODE_MAXIMIZED, "normal game launch requests a maximized window")
	scene.show_page("setup")
	type_name(scene.robot_name_edit, "Rivet")
	type_name(scene.ship_name_edit, "Stardust")
	await create_timer(0.6).timeout
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(saved.robot == "Rivet" and saved.ship == "Stardust", "typing names autosaves both values to the actual save file")
	check(not game.state.started, "autosaving names does not prematurely finish new-game setup")
	scene.name_save_button.pressed.emit()
	game.load_progress()
	check(game.state.started and game.state.robot == "Rivet" and game.state.ship == "Stardust", "setup button preserves typed names after disk reload")
	scene.show_page("settings")
	type_name(scene.robot_name_edit, "Orbit")
	type_name(scene.ship_name_edit, "Blue Dawn")
	scene.show_page("interior")
	game.load_progress()
	check(game.state.robot == "Orbit" and game.state.ship == "Blue Dawn", "navigating away flushes pending name edits before the debounce timer")
	scene.show_page("settings")
	check(scene.robot_name_edit.text == "Orbit" and scene.ship_name_edit.text == "Blue Dawn", "returning to Settings displays the persisted names")
	type_name(scene.robot_name_edit, "Bolt")
	scene.robot_name_edit.text_submitted.emit("Bolt")
	game.load_progress()
	check(game.state.robot == "Bolt" and scene.current_page == "ship", "Enter saves names and continues to the ship")
	scene.show_page("interior")
	var view: Control = scene.ship_view
	await process_frame
	await process_frame
	var overview_scale: Vector2 = view.view_transform().get_scale()
	for id in ["cockpit", "engine", "quarters"]:
		scene.select_room(id)
		await create_timer(0.9).timeout
		check(view.room_bounds(id).has_point(view.robot_position - Vector2(0, 16)), "robot follows into " + id)
		check(view.camera.has_point(view.robot_position - Vector2(0, 20)) and view.camera.encloses(view.room_bounds(id)), "room and companion fit the wider camera in " + id)
		check(view.camera == Rect2(-70, -45, 420, 240), "selecting a room does not zoom or crop the ship in " + id)
		check(view.view_transform().get_scale().is_equal_approx(overview_scale), "inspector layout does not magnify the ship for " + id)
	# Drive production movement with controlled elapsed time to test collision logic.
	view.set_process(false)
	view.robot_position = Vector2(80, 103)
	view.door_open = {"bridge":false, "engine":false}
	view.door_progress = {"bridge":0.0, "engine":0.0}
	scene.select_room("engine")
	view.advance_robot(10.0)
	var stop_margin: float = view.robot_art.clearance(view.equipment())
	check(is_equal_approx(view.robot_position.x,95-stop_margin) and not view.door_open.bridge, "closed bridge blocks even a long movement frame without opening itself")
	view.toggle_door("bridge")
	view.door_progress.bridge = 0.5
	view.advance_robot(10.0)
	check(is_equal_approx(view.robot_position.x,95-stop_margin), "robot waits until the opening shutter clears the doorway")
	view.door_progress.bridge = 1.0
	view.advance_robot(10.0)
	check(is_equal_approx(view.robot_position.x,172-stop_margin) and view.waiting_hatch == "engine", "opening bridge resumes travel but the closed engine hatch blocks the route")
	view.toggle_door("engine")
	view.door_progress.engine = 1.0
	view.advance_robot(10.0)
	check(view.robot_position == Vector2(205,103), "opening the engine hatch resumes the pending room destination")
	view.toggle_door("engine")
	view.door_progress.engine = 0.0
	scene.select_room("cockpit")
	view.advance_robot(10.0)
	check(is_equal_approx(view.robot_position.x,172+stop_margin), "closed hatch also blocks travel from the engine side")
	view.toggle_door("engine")
	view.door_progress.engine = 1.0
	view.advance_robot(0.05)
	view.toggle_door("engine")
	view.advance_robot(10.0)
	check(view.robot_position.x >= 172, "closing a hatch during approach stops the robot before crossing")
	view.toggle_door("engine")
	view.door_progress.engine = 1.0
	view.advance_robot(10.0)
	check(view.robot_position == Vector2(80,103), "robot continues toward the selected room after reopening")
	view.set_process(true)
	game.start_session(25)
	var session_id: String = game.active.id
	scene.select_room("cockpit")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == session_id and game.active.remaining_ms == 1440000, "robot movement and camera changes preserve study timing")
	game.cancel_session()
	scene.select_room("cockpit")
	await create_timer(0.9).timeout
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/room-following.png")
	scene.show_page("ship")
	game.start_session(25)
	await process_frame
	check(scene.timer_label.get_theme_font_size("font_size") >= 40 and scene.timer_label.text.contains("25:"), "compact readable main timer displays the active countdown")
	scene.open_compact()
	await process_frame
	check(scene.compact_panel.get_parent() == scene.root and scene.compact_label.get_theme_font_size("font_size") >= 32, "timer is readable inside the game and creates no popup")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/wide-ship-large-timer.png")
	scene.compact_hide_button.pressed.emit()
	game.cancel_session()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	print("USABILITY RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
