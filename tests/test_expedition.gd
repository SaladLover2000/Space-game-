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
	game.save_path = "user://expedition_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Research test"
	game.active = {}
	check(game.state.expansions.is_empty() and game.state.research.is_empty(),"new ships begin without added decks or completed lab projects")
	var before: Dictionary = game.state.duplicate(true)
	check(not game.build_expansion("lab").ok and game.state == before,"lab requires restored quarters before spending credits")
	check(not game.build_expansion("unknown").ok and game.state == before,"unknown construction IDs change no state")
	game.state.credits = 2000
	game.purchase("quarters")
	before = game.state.duplicate(true)
	check(not game.build_expansion("lab").ok and game.state == before,"construction research milestone is checked before charging")
	game.state.xp = 100
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("build")
	var build: Control = scene.expedition_panel
	before = game.state.duplicate(true)
	build.previews.lab.pressed.emit()
	check(build.view.preview_expansion == "lab" and not build.view.rooms.has("lab") and game.state == before,"preview site shows the attachment without granting ownership or an accessible room")
	build.actions.lab.pressed.emit()
	check("lab" in game.state.expansions and game.state.credits == 1810 and build.view.rooms.has("lab"),"actual Build button charges once and registers the connected lab")
	before = game.state.duplicate(true)
	check(not game.build_expansion("lab").ok and game.state == before,"a completed expansion cannot charge twice")
	check(not game.build_expansion("habitat").ok and game.state == before,"hydroponics requires its life-support research")
	check(game.research_project("navigation_patch").ok and "navigation_patch" in game.state.research,"lab project unlocks the navigation software state")
	check(game.research_project("habitat_systems").ok and game.build_expansion("habitat").ok,"research unlocks the next vertical attachment")
	check(game.build_expansion("fabrication").ok and game.research_project("deep_scanner").ok,"workshop and sensor project complete through their real prerequisites")
	check(game.state.expansions.size() == 3 and game.state.research.size() == 3 and game.state.xp == 100,"three physical expansions and three projects persist without spending milestone XP")
	game.load_progress()
	check(game.state.expansions.size() == 3 and "deep_scanner" in game.state.research,"construction and research survive actual disk reload")
	var good_path: String = game.save_path
	game.state.research.erase("navigation_patch")
	game.save_path = "res://missing_expansion_save_folder/save.json"
	before = game.state.duplicate(true)
	check(not game.research_project("navigation_patch").ok and game.state == before,"failed project persistence rolls back credits and completion")
	game.save_path = good_path
	game.state.research.append("navigation_patch")
	game.save_progress()
	scene.show_page("interior")
	var view: Control = scene.ship_view
	view.set_process(false)
	check(view.rooms.has("lab") and view.rooms.has("fabrication") and view.rooms.has("habitat"),"owned lower decks appear as actual selectable rooms")
	check(view.camera.encloses(view.room_bounds("habitat")),"Fit ship includes the deepest attached deck")
	view.robot_position = Vector2(205,103)
	view.door_open.engine = false
	view.door_progress.engine = 0
	view.follow_robot("lab")
	view.advance_robot(10)
	check(view.robot_position.y == 103 and view.robot_position.x > 172,"closed upper engine hatch blocks the route to the lift")
	view.toggle_door("engine")
	view.door_progress.engine = 1
	for i in range(6): view.advance_robot(10)
	check(view.robot_position == Vector2(130,240),"robot follows the connected lift route into the lab")
	view.follow_robot("habitat")
	for i in range(6): view.advance_robot(10)
	check(view.robot_position == Vector2(130,316),"robot can reach the next lower deck through the same shaft")
	view.request_sit()
	for i in range(7): view.advance_robot(10)
	check(view.robot_seated,"robot can return from a lower deck to the pilot chair")
	scene.show_page("bridge")
	scene.bridge_view.set_mode("navigation")
	check(scene.bridge_view.work_state().contains("installed"),"researched software changes the live bridge work state")
	scene.bridge_view.set_mode("rest")
	check(scene.bridge_view.mode == "rest","bridge task controls can stop the work animation")
	scene.show_page("3d")
	await process_frame
	await process_frame
	var viewer: Control = scene.ship_3d
	check(is_instance_valid(viewer.camera) and viewer.mesh_count > 80,"mesh inspector constructs a real camera and detailed mesh components")
	check(not viewer.pixel_style and viewer.viewport_container.visible,"3D tab defaults to a freely orbiting real model")
	var seen := {}
	for i in range(8):
		viewer.yaw = -0.85+i*TAU/8
		seen[viewer.frame_index()] = true
	check(seen.size() == 8,"turning the diorama visits all eight separate art views")
	viewer.reset_view()
	var transform: Transform3D = viewer.model.transform
	var camera_position: Vector3 = viewer.camera.position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100,100)
	viewer._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(180,140)
	viewer._gui_input(motion)
	check(viewer.camera.position != camera_position and viewer.model.transform == transform,"3D drag changes the camera while leaving the ship transform fixed")
	viewer.set_pixel_style(false)
	check(viewer.viewport_container.visible and viewer.scanner.visible,"optional free-orbit mesh mode and researched scanner remain available")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix): DirAccess.remove_absolute(game.save_path+suffix)
	print("EXPEDITION RESULT: ",failures," failures; rendered GPU appearance is not validated headlessly")
	quit(0 if failures == 0 else 1)

