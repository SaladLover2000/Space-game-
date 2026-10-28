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
	game.save_path = "user://robot_store_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.focus_task = "Test focus task"
	game.state.started = true
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("shop")
	await process_frame
	var shop: Control = scene.workshop
	check(game.parts.filter(func(item): return item.slot.begins_with("robot_")).size() == 31, "robot catalog contains twenty-five hardware designs plus six independent finishes")
	var before: Dictionary = game.state.duplicate(true)
	check(not game.buy_part("robot_shell_copper").ok and game.state == before, "unaffordable robot upgrade changes no progress")
	game.state.credits = 1000
	before = game.state.duplicate(true)
	check(not game.buy_part("robot_core_solar").ok and game.state == before, "robot research gate cannot be bypassed")
	game.state.xp = 100
	for slot in ["robot_shell", "robot_visor", "robot_arms", "robot_legs", "robot_core"]:
		shop.category_picker.item_selected.emit(shop.category_indices[slot])
		check(shop.robot_preview.visible and not shop.ship_view.visible and shop.cards.get_child_count() == 5, "robot category shows its portrait and five real part cards: " + slot)
	shop.select_slot("robot_shell")
	before = game.state.duplicate(true)
	shop.preview_buttons.robot_shell_copper.pressed.emit()
	check(shop.robot_preview.preview_equipped.robot_shell == "robot_shell_copper" and game.state == before, "robot preview affects the displayed outfit without charging or equipping")
	shop.rack_button.pressed.emit()
	shop.robot_preview.advance_service(2)
	shop.action_buttons.robot_shell_copper.pressed.emit()
	check(game.state.equipped.robot_shell == "robot_shell_copper" and game.state.credits == 965, "robot Buy button deducts the exact price and equips the shell")
	before = game.state.duplicate(true)
	game.buy_part("robot_shell_copper")
	check(game.state == before, "buying an owned robot part cannot charge twice")
	game.equip_part("robot_shell_stock")
	game.equip_part("robot_shell_copper")
	check(game.state.credits == 965, "owned robot equipment swaps freely")
	game.load_progress()
	check(game.state.equipped.robot_shell == "robot_shell_copper", "robot outfit survives actual disk reload")
	var good_path: String = game.save_path
	game.save_path = "res://missing_robot_save_directory/save.json"
	before = game.state.duplicate(true)
	check(not game.buy_part("robot_arms_utility").ok and game.state == before, "failed robot purchase save rolls back money ownership and equipment")
	game.save_path = good_path
	game.save_progress()
	shop.select_slot("engine")
	check(shop.ship_view.visible and not shop.robot_preview.visible, "ship category restores the ship preview")
	var view: Control = shop.ship_view
	var initial_camera: Rect2 = view.camera
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = view.size * 0.5
	view._gui_input(wheel)
	check(view.camera.size.x < initial_camera.size.x and view.zoom_level > 1.0, "actual wheel-up input zooms the ship in")
	view.focus_room("engine")
	await create_timer(0.6).timeout
	check(view.zoom_level > 1.0 and view.camera.size.x < initial_camera.size.x, "selecting a room preserves the user chosen zoom")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	view._gui_input(wheel)
	check(is_equal_approx(view.zoom_level, 1.0), "wheel-down input reverses one zoom step")
	view.change_zoom(1000)
	check(is_equal_approx(view.zoom_level, 2.8), "zoom-in clamps to a usable maximum")
	view.change_zoom(0.00001)
	check(is_equal_approx(view.zoom_level, 0.65), "zoom-out clamps to a usable minimum")
	view.reset_zoom()
	check(view.camera == initial_camera, "Fit ship restores the wide default camera")
	var art := preload("res://assets/pixel_ship_art.gd").new()
	check(art.system_status([],0.1).engine_broken and art.system_status([],0.1).warning_on and not art.system_status([],0.8).warning_on, "broken engine warning alternates between on and off")
	check(not art.system_status(["engine","cockpit","quarters"],0.1).engine_broken and not art.system_status(["engine","cockpit","quarters"],0.1).bridge_broken, "restored rooms disable their broken fittings")
	scene.show_page("ship")
	game.start_session(25)
	scene.open_compact()
	var panel: Control = scene.compact_panel
	scene.show_page("robot")
	check(scene.compact_panel == panel and not panel.visible and not game.active.is_empty(), "shop hides the timer panel without creating another panel or stopping the session")
	scene.show_page("ship")
	scene.open_compact()
	scene.compact_pause_button.pressed.emit()
	check(game.active.paused, "in-game timer Pause uses the real session action")
	scene.compact_hide_button.pressed.emit()
	check(not panel.visible and game.active.paused, "Hide puts the timer away without canceling or changing session state")
	scene.open_compact()
	check(scene.compact_panel == panel and panel.visible, "timer reopens using the same in-game panel")
	check(scene.find_children("*", "Window", true, false).filter(func(window): return window.visible and window.force_native).is_empty(), "timer and shop create no popup windows")
	game.cancel_session()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	print("ROBOT STORE RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)

