extends SceneTree
var failures: int = 0
func check(value: bool, description: String) -> void:
	if value: print("PASS: ",description)
	else:
		failures += 1
		push_error(description)
func click(view: Control, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = view.view_transform()*point
	event.pressed = true
	view._gui_input(event)
	event.pressed = false
	view._gui_input(event)
func midpoint(points: PackedVector2Array, bottom: bool) -> Vector2:
	return (points[2]+points[3])/2 if bottom else (points[0]+points[1])/2
func emitter_counts(image: Image, region: Rect2) -> Dictionary:
	var result := {"blue":0,"orange":0}
	for y in range(int(region.position.y),int(region.end.y)):
		for x in range(int(region.position.x),int(region.end.x)):
			var color := image.get_pixel(x,y)
			if color.a < 0.5: continue
			if color.b > 0.55 and color.b > color.r*2 and color.g > 0.30: result.blue += 1
			if color.r > 0.6 and color.r > color.g*1.25 and color.g > color.b*1.8: result.orange += 1
	return result
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://immersive_%s.json" % Time.get_ticks_usec()
	var save_path: String = game.save_path
	game.state = game.defaults()
	game.active = {}
	game.state.started = true
	game.state.focus_task = "Inspect spaceship systems"
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	await process_frame
	check(not scene.nav_buttons.has("menu") and not scene.nav_buttons.has("interior"),"one main Ship navigation replaces duplicate Home and Interior activities")
	click(scene.ship_view,Vector2(80,75))
	await process_frame
	check(scene.current_page == "bridge" and scene.bridge_view.actor_state().seated,"actual cockpit click enters immersive control room with a seated navigation pose")
	scene.return_to_ship()
	await process_frame
	check(scene.current_page == "ship" and scene.ship_view.robot_seated,"exiting bridge restores the cutaway and seated companion context")
	scene.companion_room = "quarters"
	scene.room_hatches.engine = false
	scene.ship_view.door_open.engine = false
	scene.enter_room("engine")
	await process_frame
	check(scene.current_page == "engine_bay" and not scene.engine_panel.view.actor_present,"closed engine hatch prevents companion teleporting into the immersive engine room")
	scene.open_room_hatches("engine")
	check(scene.engine_panel.view.actor_present,"opening the connecting hatch admits the companion")
	scene.return_to_ship()
	await process_frame
	click(scene.ship_view,scene.ship_view.object_bounds("quarters",0).get_center())
	await process_frame
	check(scene.current_page == "charging" and scene.charging_view.mode == "charging","clicking the actual charging cradle opens charging rather than the robot workshop")
	check(scene.charging_view.charging_mood() == "charging","an incomplete battery sleeps in the charging cradle")
	game.state.battery = 100
	check(scene.charging_view.charging_mood() == "idle","a full battery wakes the companion and ends the special charging-light state")
	game.set_robot_light("blue")
	var art: RefCounted = load("res://assets/robot_art.gd").new()
	var awake: Image = art.finished_texture("robot_visor_stock",{},0,"idle").get_image()
	var asleep: Image = art.finished_texture("robot_visor_stock",{},0,"charging").get_image()
	check(awake.get_data() != asleep.get_data(),"charging switches off actual optic pixels instead of placing a decorative bar next to the robot")
	var normal_core: Image = art.finished_texture("robot_core_stock",{},0,"idle").get_image()
	var charge_core: Image = art.finished_texture("robot_core_stock",{},0,"charging").get_image()
	check(normal_core.get_data() != charge_core.get_data() and game.state.robot_light == "blue","orange charging core is temporary and preserves the selected normal blue optics")
	check(emitter_counts(awake,art.source("robot_visor_stock")).blue > 10 and emitter_counts(asleep,art.source("robot_visor_stock")).blue == 0,"charging removes bright blue optic pixels from the actual head component")
	check(emitter_counts(charge_core,art.source("robot_core_stock")).orange > 10 and emitter_counts(normal_core,art.source("robot_core_stock")).blue > 10,"actual core pixels are orange while charging and blue while awake")
	check(not game.set_robot_light("orange") and game.state.robot_light == "blue","invalid normal optics settings cannot overwrite the saved light choice")
	scene.return_to_ship()
	await process_frame
	click(scene.ship_view,scene.ship_view.object_bounds("quarters",2).get_center())
	await process_frame
	check(scene.current_page == "robot" and scene.workshop.selected_slot == "robot_shell","the parts locker opens the categorized robot workshop")
	game.start_session(25)
	var session_id: String = game.active.id
	var remaining: int = game.active.remaining_ms
	scene.enter_room("engine")
	await process_frame
	check(game.active.id == session_id and game.active.remaining_ms == remaining,"room transitions preserve the actual running focus checkpoint")
	var original: Dictionary = game.state.duplicate(true)
	scene.engine_panel.preview_buttons.pump.pressed.emit()
	check(game.state == original and scene.engine_panel.view.preview_tiers.pump == 1,"engine preview changes only the displayed assembly, with no purchase or save mutation")
	var engine_view: Control = scene.engine_panel.view
	engine_view.set_process(false)
	engine_view.choose_task(2)
	var actor_x: float = engine_view.actor_x
	engine_view._process(1)
	check(engine_view.actor_x > actor_x and engine_view.actor_x < 0.69,"a requested parts-sorting task walks toward the crates instead of teleporting between work positions")
	check(not game.upgrade_engine_module("pump").ok,"broken engines cannot silently accept performance upgrades")
	game.state.credits = 2000
	game.state.xp = 200
	game.purchase("engine")
	var paid_before: int = game.state.credits
	var assemblies: RefCounted = scene.engine_panel.view.machinery
	var old_source: Rect2 = assemblies.layout(game.state.engine_modules,100,true)[0].source
	check(game.upgrade_engine_module("pump").ok and game.state.credits == paid_before-35,"first turbopump upgrade charges its catalog price exactly once")
	check(assemblies.layout(game.state.engine_modules,100,true)[0].source != old_source,"installed turbopump uses a different actual sprite region after purchase")
	var state_before: Dictionary = game.state.duplicate(true)
	game.save_path = "user://missing_immersive_directory/save.json"
	check(not game.upgrade_engine_module("pump").ok and game.state == state_before,"failed engine-upgrade persistence rolls back both credits and tier")
	game.save_path = save_path
	check(not game.set_flight_mode("cruise").ok,"powered cruise rejects an unprepared nozzle")
	game.upgrade_engine_module("nozzle")
	check(game.set_flight_mode("cruise").ok and game.flight_speed() == 2.5,"prepared propulsion enables actual faster cruise")
	check(not game.set_flight_mode("burn").ok,"maximum thrust remains locked before complete propulsion and navigation upgrades")
	for id in ["pump","injector","cooling","nozzle"]:
		while game.state.engine_modules[id] < 3: game.upgrade_engine_module(id)
	game.state.equipped.hull = "hull_shielded"
	game.state.research.append("navigation_patch")
	check(game.set_flight_mode("burn").ok and game.flight_speed() == 6,"complete propulsion, thermal cladding and navigation enable maximum thrust")
	game.state.credits = 1000
	game.state.cruise_seconds = 185
	check(not game.dock_station().ok,"a station contact still rejects docking without approach sensors")
	game.buy_part("antenna_sensor")
	check(not game.mount_sensor("aft","antenna_sensor").ok,"docking LiDAR cannot be installed behind the ship with no approach sightline")
	check(game.mount_sensor("fore","antenna_sensor").ok,"owned LiDAR can be mounted on the forward approach hardpoint")
	game.buy_part("antenna_dish")
	check(game.mount_sensor("aft","antenna_dish").ok,"a communications sensor can coexist at a separate aft hardpoint")
	var parts: RefCounted = load("res://assets/ship_parts_art.gd").new()
	var sensors: Array = parts.installed_parts(game.state.equipped).filter(func(piece): return piece.has("mount"))
	check(sensors.size() == 2 and sensors[0].rect != sensors[1].rect,"multiple mounted sensors occupy distinct physical locations on the actual cutaway")
	check(game.state.equipped.antenna == "antenna_dish" and game.has_docking_sensor(),"forward-mounted LiDAR provides actual docking capability independently of the last selected sensor")
	var fee_before: int = game.state.credits
	check(game.dock_station().ok and game.state.credits == fee_before-350,"qualified docking charges the displayed 350-credit fee")
	fee_before = game.state.credits
	check(not game.dock_station().ok and game.state.credits == fee_before,"repeated docking cannot charge a second entry fee")
	var position: float = game.state.cruise_seconds
	game.advance_flight(10)
	game.advance(game.last_tick+1000)
	check(game.state.cruise_seconds == position and game.active.remaining_ms == remaining-1000,"docking freezes travel while the real focus timer continues")
	game.undock_station()
	check(game.state.docked_station.is_empty(),"undocking restores travel permission")
	var region: Rect2 = art.source("robot_shell_stock")
	var worn: Image = art.finished_texture("robot_shell_stock",{}).get_image()
	game.service_robot(true)
	game.service_robot(true)
	var repaired: Image = art.finished_texture("robot_shell_stock",{}).get_image()
	check(worn.get_region(Rect2i(region)).get_data() != repaired.get_region(Rect2i(region)).get_data(),"robot care removes actual wear from the selected component pixels")
	for angle in [0,1,2,3]:
		var pieces: Array = art.oriented_pose({},4,"inspecting",false,false,angle)
		var connected := true
		for side in ["left","right"]:
			var upper: Dictionary = pieces.filter(func(part): return part.get("segment","") == "upper_arm" and part.side == side)[0]
			var lower: Dictionary = pieces.filter(func(part): return part.get("segment","") == "forearm" and part.side == side)[0]
			connected = connected and midpoint(art.vertices(upper),true).distance_to(midpoint(art.vertices(lower),false)) < 0.01
		check(connected,"rendered elbow endpoints stay attached while bending in direction "+str(angle))
		var knees_connected := true
		for side in ["left","right"]:
			var thigh: Dictionary = pieces.filter(func(part): return part.get("segment","") == "thigh" and part.side == side)[0]
			var shin: Dictionary = pieces.filter(func(part): return part.get("segment","") == "shin" and part.side == side)[0]
			knees_connected = knees_connected and midpoint(art.vertices(thigh),true).distance_to(midpoint(art.vertices(shin),false)) < 0.3
		check(knees_connected,"crouching knees remain connected in direction "+str(angle))
		var sole_y := -INF
		for part in pieces:
			if part.id.begins_with("robot_legs"):
				for point in art.vertices(part): sole_y = maxf(sole_y,point.y)
		check(absf(sole_y) < 0.01,"bending keeps the visible shoe soles on the floor in direction "+str(angle))
	var seated: Array = art.oriented_pose({},4,"typing",false,true,1)
	check(seated.filter(func(part): return part.get("segment","") == "thigh")[0].rotation == -PI/2,"profile sitting pose folds thighs horizontally instead of standing in front of the chair")
	check(game.robot_thought("engine",0) != game.robot_thought("engine",14) and game.robot_thought("engine",0) != game.robot_thought("cockpit",0),"thoughts cycle through different phrases and reflect the current room")
	check(not game.buy_quarters_decor("terrarium").ok,"quarters decor requires restoring the room first")
	game.purchase("quarters")
	check(game.buy_quarters_decor("terrarium").ok and "terrarium" in game.state.quarters_decor,"restored quarters accept persistent decor")
	var hull: RefCounted = load("res://assets/pixel_ship_art.gd").new()
	var pod_area := Rect2(252,48,48,66)
	var hidden := true
	for rect in hull.skin_regions({"engine":"engine_hauler"}): hidden = hidden and not rect.intersects(pod_area)
	check(hidden,"replacement engines exclude the old nacelles from actual hull draw geometry")
	scene.show_page("stations")
	await process_frame
	check(get_nodes_in_group("volumetric_station").size() == 1,"station approach builds real volumetric geometry rather than stretching a station sticker")
	game.state.credits = 1000
	game.state.hull_integrity = 99
	check(not game.land_planet().ok,"planetary entry rejects a damaged hull despite sufficient credits and engine tiers")
	game.state.hull_integrity = 100
	check(not game.planet_contact().is_empty() and game.land_planet().ok and game.state.credits == 500,"eligible planetary approach charges its displayed 500-credit clearance")
	check(not game.land_planet().ok and game.state.credits == 500,"repeated planetary entry cannot charge a second clearance fee")
	game.undock_station()
	scene.show_page("planet")
	await process_frame
	check(get_nodes_in_group("volumetric_planet").size() == 1,"planet approach renders a textured sphere with actual depth")
	game.save_progress()
	game.load_progress()
	check(game.state.robot_light == "blue" and game.state.sensor_mounts.size() == 2 and game.state.engine_modules.pump == 3 and "terrarium" in game.state.quarters_decor,"optics, sensor locations, propulsion tiers and decor survive an actual save and reload")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
	print("IMMERSIVE PROGRESSION RESULT: ",failures," failures; headless behavior and asset checks do not verify GPU appearance")
	quit(0 if failures == 0 else 1)
