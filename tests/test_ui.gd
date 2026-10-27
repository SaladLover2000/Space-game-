extends SceneTree

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
	for page in ["ship", "robot", "shop", "stats", "settings", "menu"]:
		scene.show_page(page)
		await process_frame
		print("UI opened: ", page)
	scene.show_page("ship")
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/prototype.png")
	game.start_session(1)
	game.toggle_pause()
	game.toggle_pause()
	scene.open_compact()
	await process_frame
	game.active.remaining_ms = 0
	game.finish_session()
	await process_frame
	assert(scene.notice.contains("Session complete"))
	assert(scene.start_button.disabled == false)
	assert(scene.compact_label.text.contains("Ready"))
	game.state.credits = 50
	game.purchase("engine")
	scene.show_page("shop")
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("UI RESULT: all pages, compact timer, completion chime, reward refresh and restored shop exercised")
	scene.sound_player.stop()
	scene.sound_player.stream = null
	await create_timer(0.1).timeout
	scene.queue_free()
	await process_frame
	quit()
