extends SceneTree
## Real-time native-window acceptance check; takes about 65 seconds.
var completed_at: int = 0
var started_at: int = 0
var completion_count: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this acceptance test with a native graphical window, without --headless.")
		quit(1)
		return
	var game := root.get_node("Game")
	game.save_path = "user://minimized_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.sound = false
	game.active = {}
	game.completed.connect(func(_credits: int, _xp: int): completed_at = Time.get_ticks_msec(); completion_count += 1)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	started_at = Time.get_ticks_msec()
	game.start_session(1)
	root.mode = Window.MODE_MINIMIZED
	await create_timer(1).timeout
	var was_minimized := root.mode == Window.MODE_MINIMIZED
	print("Native window minimized: ", was_minimized, ". Waiting for a real one-minute completion...")
	await create_timer(64).timeout
	var elapsed := completed_at - started_at
	var passed: bool = was_minimized and completion_count == 1 and elapsed >= 60000 and elapsed < 65000 and game.state.credits == 2 and game.state.history.size() == 1 and game.active.is_empty()
	print("MINIMIZED RESULT: ", "PASS" if passed else "FAIL", "; completed after ", elapsed, " ms; completion count ", completion_count, "; credits ", game.state.credits)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)
