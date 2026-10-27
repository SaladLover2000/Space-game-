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
	game.set_process(false)
	game.save_path = "user://drift_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	await process_frame
	var view: Control = scene.ship_view
	view.set_process(false)
	var at_start: Vector2 = view.ship_drift(0) * Vector2(140, 81)
	var later: Vector2 = view.ship_drift(6) * Vector2(140, 81)
	check(at_start.distance_to(later) > 1, "ship actually changes position over time")
	check(at_start.distance_to(later) < 4, "drift stays gentle and bounded")
	view.clock = 37.0
	for id in ["cockpit", "quarters", "engine"]:
		var point: Vector2 = view.view_transform() * view.room_bounds(id).get_center()
		check(view.room_at(point) == id, "room picking follows drifting hull: " + id)
	var backdrop: RefCounted = view.backdrop
	check(backdrop.planet_position(0, 40).x > backdrop.planet_position(0, 0).x + 20, "large planet passes the ship with elapsed time")
	check(backdrop.planet_position(1, 40).x - backdrop.planet_position(1, 0).x > backdrop.planet_position(0, 40).x - backdrop.planet_position(0, 0).x, "planet layers move at different parallax speeds")
	var puff_start: Dictionary = view.smoke_particle(0, 0)
	var puff_later: Dictionary = view.smoke_particle(0, 2)
	check(puff_later.position.x > puff_start.position.x and puff_later.radius > puff_start.radius, "white exhaust puffs move away and expand")
	check(puff_later.alpha < puff_start.alpha and puff_later.alpha > 0, "exhaust fades instead of accumulating forever")
	check(view.smoke_particle(0, 4) == puff_start, "exhaust recycles after a bounded lifetime")
	var original_state: Dictionary = game.state.duplicate(true)
	game.start_session(25)
	var session_id: String = game.active.id
	scene.show_page("drift")
	await process_frame
	check(scene.ship_view.exterior and scene.drift_status.text.contains("Study"), "exterior drift screen opens with study status")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == session_id and game.active.remaining_ms == 1440000, "exterior view preserves the running study timer")
	check(game.state.credits == original_state.credits and game.state.xp == original_state.xp and game.state.owned == original_state.owned, "scenery grants no rewards or discoveries")
	game.cancel_session()
	scene.ship_view.clock = 6
	scene.ship_view.set_process(false)
	scene.ship_view.queue_redraw()
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		var before: PackedByteArray = root.get_texture().get_image().get_data()
		var motion_start: float = scene.ship_view.clock
		scene.ship_view.set_process(true)
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		check(scene.ship_view.clock > motion_start + 0.5, "native render advances scenery with real frame time")
		check(root.get_texture().get_image().get_data() != before, "native frames visibly change while scenery animates")
		root.get_texture().get_image().save_png("res://docs/drift-view.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	print("DRIFT RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
