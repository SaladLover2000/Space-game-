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
	var game := root.get_node("Game")
	game.save_path = "user://ui_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_page("setup")
	game.rename_companions("Nova", "Quiet Horizon")
	check(game.state.robot == "Nova" and game.state.ship == "Quiet Horizon" and game.state.started, "naming persists companion and ship")
	for page in ["ship", "drift", "robot", "shop", "stats", "settings", "menu"]:
		scene.show_page(page)
		await process_frame
		print("UI opened: ", page)
	scene.show_page("ship")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/prototype.png")
	scene.duration.value = 1
	scene.start_button.pressed.emit()
	check(not game.active.is_empty() and game.active.minutes == 1 and scene.start_button.disabled, "Start button starts selected duration and disables overlapping starts")
	scene.pause_button.pressed.emit()
	check(game.active.paused and scene.pause_button.text == "Resume", "Pause button pauses game state and becomes Resume")
	scene.pause_button.pressed.emit()
	check(not game.active.paused and scene.pause_button.text == "Pause", "Resume button resumes game state and becomes Pause")
	scene.open_compact()
	await process_frame
	check(scene.compact_window.always_on_top and scene.compact_window.force_native and scene.compact_window.visible, "compact timer requests a visible native topmost window")
	scene.compact_window.close_requested.emit()
	check(not scene.compact_window.visible and not game.active.is_empty(), "closing compact window hides it without canceling study")
	scene.open_compact()
	check(scene.compact_window.visible, "compact timer can reopen")
	game.active.remaining_ms = 0
	game.finish_session()
	await process_frame
	check(scene.notice.contains("Session complete"), "completion displays feedback")
	check(not scene.start_button.disabled and scene.pause_button.disabled, "completion restores Start and disables Pause")
	check(scene.compact_label.text.contains("Ready"), "compact display updates on completion")
	game.state.credits = 50
	game.purchase("engine")
	scene.show_page("shop")
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("UI RESULT: ", failures, " failures; screen creation is smoke coverage, button/state checks are assertions; audible sound is not verified")
	scene.sound_player.stop()
	scene.sound_player.stream = null
	await create_timer(0.1).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
