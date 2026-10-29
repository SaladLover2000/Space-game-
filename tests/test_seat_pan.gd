extends SceneTree
var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func mouse(view: Control, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	view._gui_input(event)

func motion(view: Control, position: Vector2, held: bool = true) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	view._gui_input(event)

func click_world(view: Control, point: Vector2) -> void:
	var position: Vector2 = view.view_transform()*point
	mouse(view,position,true)
	mouse(view,position,false)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://seat_pan_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.focus_task = "Test focus task"
	game.state.started = true
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("interior")
	await process_frame
	var view: Control = scene.ship_view
	# Exercise the low-level overview rig/inspector independently; immersive UI routing has its own end-to-end suite.
	view.immersive_routes = false
	view.room_selected.disconnect(scene.enter_room)
	view.room_selected.connect(scene.select_room)
	view.object_selected.disconnect(scene.route_object)
	view.object_selected.connect(scene.inspect_object)
	view.set_process(false)
	var seat: Vector2 = view.object_bounds("cockpit",2).get_center()
	var cursor: Vector2 = view.view_transform()*seat
	var original_camera: Rect2 = view.camera
	var original_destination: Vector2 = view.robot_destination
	mouse(view,cursor,true)
	check(not view.seat_requested and not view.robot_seated, "press alone does not activate the pilot seat before drag detection")
	var shift := Vector2(90,45)
	var scale: float = minf(view.size.x/view.camera.size.x,view.size.y/view.camera.size.y)
	motion(view,cursor+shift)
	check(view.camera.position.is_equal_approx(original_camera.position-shift/scale), "holding left mouse pans horizontally and vertically by the screen delta")
	mouse(view,cursor+shift,false)
	check(not view.seat_requested and view.robot_destination == original_destination and scene.selected_room.is_empty(), "dragging from the seat does not sit or select a room")
	check(not view.pan_pressed and not view.pan_dragging, "release ends the drag")
	var center: Vector2 = view.camera.get_center()
	view.change_zoom(1.15)
	check(view.camera.get_center().is_equal_approx(center), "wheel zoom preserves the dragged camera center")
	view.focus_room("quarters")
	check(view.camera.get_center().is_equal_approx(center), "room selection preserves the user pan position")
	view.reset_zoom()
	check(view.camera == original_camera and view.zoom_level == 1.0, "Fit ship resets both pan and zoom")
	var before_door: bool = view.door_open.bridge
	cursor = view.view_transform()*Vector2(95,87)
	mouse(view,cursor,true)
	motion(view,cursor+Vector2(20,-30))
	mouse(view,cursor+Vector2(20,-30),false)
	check(view.door_open.bridge == before_door, "dragging from a hatch does not toggle it")
	view.reset_zoom()
	mouse(view,view.size/2,true)
	motion(view,Vector2(-100,-100))
	mouse(view,Vector2(-100,-100),false)
	check(not view.pan_pressed, "release outside the canvas ends the drag without clicking")
	view.reset_zoom()
	mouse(view,view.size/2,true)
	motion(view,view.size/2+Vector2(20,0),false)
	check(not view.pan_pressed and view.camera == original_camera, "a lost mouse-button state cancels the drag safely")
	view.robot_position = Vector2(205,103)
	view.robot_destination = view.robot_position
	view.door_open = {"bridge":false,"engine":false}
	view.door_progress = {"bridge":0.0,"engine":0.0}
	game.start_session(25)
	var session: Dictionary = game.active.duplicate(true)
	var progress: Dictionary = game.state.duplicate(true)
	click_world(view,seat)
	check(scene.selected_room == "cockpit" and view.seat_requested and not view.robot_seated, "clicking the chair from another room requests a walk to the pilot seat")
	view.advance_robot(10)
	check(not view.robot_seated and is_equal_approx(view.robot_position.x,172+view.robot_art.clearance(view.equipment())), "closed engine hatch blocks the route to the seat")
	view.toggle_door("engine")
	view.door_progress.engine = 1
	view.advance_robot(10)
	check(not view.robot_seated and is_equal_approx(view.robot_position.x,95+view.robot_art.clearance(view.equipment())), "the remaining closed bridge hatch also blocks seating")
	view.toggle_door("bridge")
	view.door_progress.bridge = 1
	view.advance_robot(10)
	check(view.robot_seated and not view.seat_requested and view.robot_position == view.PILOT_SEAT, "robot sits only after reaching the chair through open hatches")
	var pose: Array = view.robot_art.pose(view.equipment(),0,"idle",false,true)
	check(pose.size() == 13 and pose.filter(func(part): return absf(part.rotation) > 0.5).size() >= 4, "seated renderer articulates thighs, shins, upper arms, forearms and hands")
	var hip_alignment := true
	for legs in ["robot_legs_stock","robot_legs_boots","robot_legs_strider"]:
		var outfit: Dictionary = view.equipment().duplicate(true)
		outfit.robot_legs = legs
		var origin_y: float = view.PILOT_CUSHION_Y+view.robot_art.part_size(legs,"left").y-1
		for part in view.robot_art.pose(outfit,0,"idle",false,true):
			if part.id == outfit.robot_shell:
				hip_alignment = hip_alignment and is_equal_approx(origin_y+part.rect.end.y,view.PILOT_CUSHION_Y)
	check(hip_alignment, "different leg lengths align the seated hips to the same chair cushion")
	scene.refresh()
	check(view.robot_seated, "refreshing equipment descriptions does not restart or cancel sitting")
	var stand_buttons: Array = scene.room_panel.get_children().filter(func(node): return node is Button and node.text == "Stand up")
	check(stand_buttons.size() == 1, "cockpit inspector exposes an explicit Stand up action")
	stand_buttons[0].pressed.emit()
	check(not view.robot_seated and not view.seat_requested and view.robot_position.y == 103, "Stand up returns the robot to the walking deck")
	scene.room_panel.get_child(6).pressed.emit()
	view.advance_robot(10)
	check(view.robot_seated, "the actual Pilot seat equipment button also seats the robot")
	scene.select_room("quarters")
	check(not view.robot_seated and not view.seat_requested and view.robot_destination == Vector2(143,103), "choosing another room stands up and resumes following")
	check(game.active == session and game.state == progress, "sitting standing and camera controls leave the study session and rewards unchanged")
	scene.show_page("shop")
	await process_frame
	view = scene.workshop.ship_view
	view.set_process(false)
	cursor = view.view_transform()*Vector2(249,80)
	var selected: String = scene.workshop.selected_slot
	mouse(view,cursor,true)
	motion(view,cursor+Vector2(40,20))
	mouse(view,cursor+Vector2(40,20),false)
	check(scene.workshop.selected_slot == selected and view.camera != original_camera, "workshop dragging pans without selecting a component")
	game.cancel_session()
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix):
			DirAccess.remove_absolute(game.save_path+suffix)
	print("SEAT PAN RESULT: ", failures, " failures; actual input callbacks are exercised without OS mouse automation")
	quit(0 if failures == 0 else 1)
