extends SceneTree
var failures: int = 0
func check(value: bool, description: String) -> void:
	if value: print("PASS: ",description)
	else:
		failures += 1
		push_error(description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://focus_cruise_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.active = {}
	check(not game.start_session(25) and game.active.is_empty(),"empty focus task is rejected by authoritative session logic")
	game.state.focus_task = "   "
	check(not game.start_session(25),"whitespace cannot bypass the required task")
	game.active = {"id":"legacy","minutes":25,"remaining_ms":1500000,"paused":true}
	game.state.focus_task = ""
	game.toggle_pause()
	check(game.active.paused,"an unlabeled legacy session cannot resume without a task")
	game.state.focus_task = "Finish the saved work"
	game.toggle_pause()
	check(not game.active.paused and game.active.task == "Finish the saved work","giving a legacy session a task safely enables resume")
	game.cancel_session()
	game.state.focus_task = ""
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	check(scene.start_button.disabled,"focus Start is disabled until a task is entered")
	scene.focus_dock.task.text = "Read orbital mechanics"
	scene.focus_dock.task.text_changed.emit("Read orbital mechanics")
	check(not scene.start_button.disabled,"typing a meaningful task enables the actual Start button")
	scene.start_button.pressed.emit()
	check(game.active.get("task","") == "Read orbital mechanics","Start flushes pending task text into the real session")
	var id: String = game.active.id
	scene.show_page("shop")
	check(not scene.focus_dock.visible and not game.active.is_empty(),"shop hides the focus bar without pausing the session")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == id and game.active.remaining_ms == 1440000,"study time continues while shopping")
	var shop: Control = scene.workshop
	await process_frame
	check(shop.side_scroll.get_parent() == shop.preview_stage.get_parent() and shop.cards.get_parent() == shop.side_scroll.get_child(0),"upgrade cards are in a side panel beside the fixed preview")
	scene.show_page("robot")
	check(scene.workshop.selected_slot == "robot_shell" and not scene.focus_dock.visible,"Robot tab directly includes robot upgrades in the game-style shop")
	scene.show_page("ship")
	await process_frame
	await process_frame
	check(scene.focus_dock.visible and scene.focus_dock.get_combined_minimum_size().y <= maxf(140,scene.timer_label.get_theme_font("font").get_height(44)+scene.timer_label.get_theme_font("font").get_height(12)+40),"returning to duty restores a compact focus dock within its font-metric height budget")
	check(scene.focus_dock.reward.text.to_utf8_buffer().size() == scene.focus_dock.reward.text.length(),"timer status uses clean ASCII separators without encoding artifacts")
	game.cancel_session()
	check(game.state.calm_lights,"steady instrument lighting is the default")
	var art: RefCounted = load("res://assets/pixel_ship_art.gd").new()
	check(art.system_status([],0.1,true).warning_on == art.system_status([],0.8,true).warning_on,"calm mode keeps the fault lamp steady across frames")
	var before: Dictionary = game.state.duplicate(true)
	var glance: Dictionary = game.resolve_encounter(0.1,0.9)
	check(glance.impact and glance.damage == 0 and game.state == before,"most direct asteroid contacts do not damage progress or hull")
	var miss: Dictionary = game.resolve_encounter(0.9,0.0)
	check(not miss.impact and miss.damage == 0,"nearby asteroid fly-bys cannot damage the ship")
	var hit: Dictionary = game.resolve_encounter(0.1,0.01)
	check(game.state.hull_integrity == 100,"a scheduled contact cannot damage the hull before the asteroid reaches it")
	game.apply_contact(hit)
	check(hit.damage == 2 and game.state.hull_integrity == 98 and game.state.credits == before.credits and game.state.xp == before.xp,"rare damaging contact removes only two hull points and no study rewards")
	game.apply_contact(hit)
	check(game.state.hull_integrity == 98,"the same impact cannot apply hull damage twice")
	for i in range(20): game.apply_contact(game.resolve_encounter(0.1,0.01))
	check(game.state.hull_integrity == 80,"encounters cannot destroy or strand the study ship")
	game.state.credits = 5
	var good_path: String = game.save_path
	game.save_path = "res://missing_hull_save_folder/save.json"
	before = game.state.duplicate(true)
	check(not game.patch_hull().ok and game.state == before,"failed hull patch persistence rolls back credits and integrity")
	game.save_path = good_path
	check(game.patch_hull().ok and game.state.hull_integrity == 90 and game.state.credits == 0,"affordable hull patch spends five credits and restores ten integrity")
	before = game.state.duplicate(true)
	check(not game.patch_hull().ok and game.state == before,"unaffordable hull repair leaves all state unchanged")
	for i in range(31): game.advance_flight(1)
	check(game.state.hull_integrity == 91,"robot can make slow free field repairs while the app is open")
	var backdrop: RefCounted = load("res://assets/space_backdrop.gd").new()
	check(backdrop.cruise_planet_position(0,120).x > backdrop.cruise_planet_position(0,0).x,"planet fly-bys advance coherently with cruise time")
	game.state.hull_integrity = 100
	game.state.cruise_seconds = 85
	var view: Control = scene.ship_view
	view.set_process(false)
	view.manual_hold = 0
	view.advance_autonomy(1)
	view.advance_robot(10)
	view.queue_redraw()
	await process_frame
	check(view.autonomous_activity == "sleeping" and view.robot_position == Vector2(143,103),"uncommanded robot goes to the habitation area to sleep")
	view.follow_robot("cockpit")
	var target: Vector2 = view.robot_destination
	view.advance_autonomy(1)
	check(view.manual_hold > 0 and view.robot_destination == target,"a direct room command takes priority over autonomous activity")
	game.start_session(25)
	view.manual_hold = 0
	view.advance_autonomy(1)
	check(view.autonomous_activity == "charging","uncommanded robot chooses the charging dock during focus")
	game.cancel_session()
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix): DirAccess.remove_absolute(game.save_path+suffix)
	print("FOCUS CRUISE RESULT: ",failures," failures; comfort and appearance still need visual review")
	quit(0 if failures == 0 else 1)
