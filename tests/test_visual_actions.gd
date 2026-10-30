extends SceneTree
var failures: int = 0
func check(value: bool, text: String) -> void:
	if value: print("PASS: ",text)
	else:
		failures += 1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func midpoint(points: PackedVector2Array, lower: bool) -> Vector2:
	return (points[2]+points[3])/2 if lower else (points[0]+points[1])/2
func mouse(view: Control, point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	view._gui_input(event)
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://visual_actions_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Visual action tests"
	var art: RefCounted = load("res://assets/robot_art.gd").new()
	var space: RefCounted = load("res://assets/space_backdrop.gd").new()
	var sky_image: Image = space.nebula.get_image()
	var sums: Array[float] = [0.0,0.0,0.0,0.0,0.0,0.0,0.0]
	var counts: Array[int] = [0,0,0,0,0,0,0]
	for y in range(sky_image.get_height()):
		for x in range(sky_image.get_width()):
			var color: Color = sky_image.get_pixel(x,y)
			sums[(x+y)%7] += (color.r+color.g+color.b)/3.0
			counts[(x+y)%7] += 1
	for i in range(7): sums[i] /= counts[i]
	check(sums.max()-sums.min() < 0.02,"actual sky pixels have no high-contrast recurring diagonal scanline pattern")
	for legs in ["robot_legs_stock","robot_legs_boots","robot_legs_strider","robot_legs_explorer","robot_legs_loader"]:
		var connected := true
		var planted := true
		var varied := false
		var previous := 0.0
		for step in range(12):
			var pieces: Array = art.pose({"robot_legs":legs},step*0.06,"inspecting",true,false,1)
			var soles := 0
			for side in ["left","right"]:
				var thigh: Dictionary = pieces.filter(func(p): return p.get("segment","") == "thigh" and p.side == side)[0]
				var shin: Dictionary = pieces.filter(func(p): return p.get("segment","") == "shin" and p.side == side)[0]
				var shoe: Dictionary = pieces.filter(func(p): return p.get("segment","") == "shoe" and p.side == side)[0]
				connected = connected and midpoint(art.vertices(thigh),true).distance_to(midpoint(art.vertices(shin),false)) < 0.01 and midpoint(art.vertices(shin),true).distance_to(midpoint(art.vertices(shoe),false)) < 0.01
				if shoe.stance:
					soles += 1
					planted = planted and absf(shoe.rect.end.y) < 0.01 and is_zero_approx(shoe.rotation)
				varied = varied or (step > 0 and absf(thigh.rotation-previous) > 0.03)
				previous = thigh.rotation
			planted = planted and soles >= 1
		check(connected,"walking hip/knee/ankle chain stays joined: "+legs)
		check(planted,"walking keeps at least one flat sole on deck: "+legs)
		check(varied,"walking bends joints rather than moving a frozen crouch: "+legs)
	var sleep_a: Array = art.oriented_pose({},0,"charging",false,false,0)
	var sleep_b: Array = art.oriented_pose({},9,"charging",false,false,0)
	var stable := true
	for i in range(sleep_a.size()): stable = stable and art.vertices(sleep_a[i]) == art.vertices(sleep_b[i])
	check(stable,"charging keeps connected static hardware without head/neck rotation or bobbing")
	for id in ["robot_visor_stock","robot_visor_wide","robot_visor_amber","robot_visor_explorer","robot_visor_loader"]:
		check(art.texture_for(id,1) == art.PROFILE_HEADS and art.texture_for(id,3) == art.PROFILE_HEADS,"both profiles use the corrected design-matched head: "+id)
	check(art.texture_for("robot_shell_stock",1) == art.SIDE_ATLAS,"corrected heads leave existing side body artwork in use")
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_page("robot")
	await process_frame
	var shop: Control = scene.workshop
	check(shop.optics_picker.get_rect().size.x >= 160 and shop.optics_picker.get_rect().size.y >= 40,"optics picker has room to show its selected value")
	check(not shop.optics_row.get_global_rect().intersects(shop.detail.get_global_rect()),"optics controls do not overlap the build-description text")
	scene.show_page("bridge")
	await process_frame
	var bridge: Control = scene.bridge_view
	bridge.set_process(false)
	var sky_a: Dictionary = bridge.window_scene(0)
	var sky_b: Dictionary = bridge.window_scene(30)
	check(not sky_a.stars.is_empty() and not sky_a.planets.is_empty(),"bridge windows show stars and a visible planet from departure")
	check(sky_a.stars != sky_b.stars and sky_a.planets[0].rect != sky_b.planets[0].rect,"bridge stars and planets change position during travel")
	var contained := true
	for planet in sky_a.planets:
		for point in planet.polygon:
			contained = contained and point.x >= bridge.size.x*0.08-0.01 and point.x <= bridge.size.x*0.92+0.01
	check(contained,"window planet geometry is clipped at the window edges")
	var pose_a: Array = art.oriented_pose({},0,"typing",false,true,2)
	var pose_b: Array = art.oriented_pose({},0.15,"typing",false,true,2)
	var key_motion := false
	var visible_hands := true
	for side in ["left","right"]:
		var hand_a: Dictionary = pose_a.filter(func(p): return p.get("segment","") == "hand" and p.side == side)[0]
		var hand_b: Dictionary = pose_b.filter(func(p): return p.get("segment","") == "hand" and p.side == side)[0]
		key_motion = key_motion or art.vertices(hand_a) != art.vertices(hand_b)
		for point in art.vertices(hand_a): visible_hands = visible_hands and bridge.actor_state().feet.y+point.y*bridge.actor_state().scale < bridge.size.y*0.65
	check(key_motion and visible_hands,"typing hands move at the keys and stay above chair occlusion")
	scene.show_page("charging")
	await process_frame
	var charging: Control = scene.charging_view
	check(is_equal_approx(charging.actor_state().feet.y,charging.size.y*0.77),"charging feet stand on the cradle platform instead of behind it")
	var before: Dictionary = game.state.duplicate(true)
	charging._process(5)
	check(game.state == before,"charging presentation grants no free battery or rewards")
	check(not charging.thought.visible,"charging has no cycling floating text or moving sleep glyphs")
	scene.show_page("engine_bay")
	await process_frame
	var bay: Control = scene.engine_panel.view
	bay.set_process(false)
	bay.choose_task(0)
	bay.actor_x = 0.20
	check(bay.actor_state().mood == "inspecting" and bay.actor_state().targets.hide_tool,"control inspection reaches toward the screen without waving a wrench")
	var inspecting: Dictionary = bay.actor_state()
	var fingertip: Vector2 = art.tool_position(game.state.equipped,bay.work_clock,3,false,"inspecting",inspecting.targets)
	fingertip.x = -fingertip.x
	fingertip = inspecting.feet+fingertip*inspecting.scale
	check(Rect2(bay.size*Vector2(0,0.58),bay.size*Vector2(0.19,0.20)).has_point(fingertip),"inspection fingertip reaches the visible console region")
	bay.choose_task(1)
	bay.actor_x = 0.43
	bay._process(0.1)
	check(bay.actor_state().mood == "sealing" and not bay.actor_state().targets.hide_tool,"seal checking selects the actual wrench/torque pose")
	bay.choose_task(2)
	bay.actor_x = 0.69
	bay._process(1)
	check(bay.sorting_state().held == 0 and not bay.is_walking(),"sorting actually lifts the first part after reaching the tray")
	var right_before: Vector2 = bay.actor_state().targets.right
	bay._process(1)
	check(bay.actor_state().targets.right != right_before,"sorting carries the part with a changing arm target")
	bay._process(1)
	check(bay.sorting_state().count == 1 and bay.sorting_state().pieces.filter(func(p): return p.sorted).size() == 1,"sorting transfers a real item into the rack")
	bay._process(16)
	check(bay.sorting_state().count == 6 and bay.sorting_state().pieces.filter(func(p): return p.sorted).size() == 6,"a full sorting cycle puts all six pieces in rack bins")
	check(game.state == before,"inspection, sealing and sorting do not change saved progress or costs")
	check(not bay.begin_assembly(),"assembly cannot stage unrepaired hardware")
	game.state.owned.append("engine")
	game.state.engine_condition = 100
	before = game.state.duplicate(true)
	scene.engine_panel.assembly_button.pressed.emit()
	check(bay.assembly_mode and bay.assembly_slots.is_empty(),"real assembly button opens a staging tray with four empty sockets")
	var tray: Array = bay.assembly_tray()
	mouse(bay,tray[0].rect.get_center(),true)
	mouse(bay,bay.assembly_socket("nozzle").get_center(),false)
	check(bay.assembly_slots.is_empty(),"dropping a part in the wrong socket cannot assemble it")
	for id in ["pump","injector","cooling","nozzle"]:
		var part: Dictionary = bay.assembly_tray().filter(func(p): return p.id == id)[0]
		mouse(bay,part.rect.get_center(),true)
		mouse(bay,bay.assembly_socket(id).get_center(),false)
	check(bay.assembly_complete() and bay.assembly_tray().is_empty(),"actual mouse drops combine all four modules into a full engine")
	check(game.state == before,"assembly is free staging and introduces no save fields, rewards or rule changes")
	game.state.credits = 1000
	game.state.xp = 1000
	scene.engine_panel.upgrade_buttons.pump.pressed.emit()
	check(game.state.engine_modules.pump == 1 and bay.assembly_mode and not bay.assembly_slots.has("pump") and bay.assembly_slots.size() == 3,"successful upgrade stages its new part for hands-on fitting")
	var engine_art: RefCounted = bay.machinery
	var supported := true
	for support in engine_art.support_layout(bay.size,game.state.engine_modules,100,true): supported = supported and support.floor >= support.rect.end.y and support.ceiling < support.rect.position.y
	check(supported,"every engine component has a floor support and suspension attachment")
	var hull: RefCounted = load("res://assets/ship_parts_art.gd").new()
	var plates: Array = hull.armor_plates("hull_ribs")
	check(plates.size() >= 8 and plates.all(func(p): return p.polygon.size() >= 4 and p.rect.size.x > p.rect.size.y),"hull reinforcement is segmented contour plates instead of vertical pasted strips")
	var skin: RefCounted = load("res://assets/pixel_ship_art.gd").new()
	var armor_attached := true
	var base: Image = skin.EXTERIOR.get_image()
	for plate in plates:
		var center := Vector2.ZERO
		for point in plate.polygon: center += point
		center /= plate.polygon.size()
		var pixel: Vector2 = (center-Vector2(-33,-39))/Vector2(333,228)*Vector2(base.get_size())
		armor_attached = armor_attached and base.get_pixelv(Vector2i(pixel)).a > 0.5
	check(armor_attached,"armor plate centers lie on actual opaque hull material rather than floating above its silhouette")
	var old_engine_hidden := true
	for rect in skin.skin_regions({"engine":"engine_ion"}): old_engine_hidden = old_engine_hidden and not rect.intersects(Rect2(238,35,62,94))
	check(old_engine_hidden,"engine replacements also remove old collars and lower rims")
	var attached := true
	var mounts: Array = hull.engine_mount_geometry({"engine":"engine_hauler"})
	for y in [64.0,98.0]:
		for x in range(232,261):
			attached = attached and mounts.any(func(m): return m.rect.has_point(Vector2(x,y)))
	check(attached,"new bolted engine mounts continuously bridge the hull-to-pod gap")
	scene.queue_free()
	await process_frame
	print("VISUAL ACTION RESULT: ",failures," failures")
	quit(0 if failures == 0 else 1)
