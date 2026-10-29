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
	game.save_path = "user://component_workshop_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Verify upgrades"
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("robot")
	await process_frame
	var shop: Control = scene.workshop
	var art: RefCounted = shop.robot_preview.art
	check(art.finish_color({}).r > 0.99 and art.finish_color({}).g > 0.94 and art.finish_color({}).b > 0.8,"base finish is warm white ceramic rather than gray metal")
	shop.category_buttons.robot_visor.pressed.emit()
	check(shop.selected_slot == "robot_visor" and shop.robot_tabs.visible,"direct Heads tab selects only head components in the retained sidebar")
	var cards_ok := true
	for card in shop.cards.get_children():
		var icons: Array = card.find_children("*","Control",true,false).filter(func(node): return node.get_script() != null and node.get_script().resource_path == "res://ui/component_icon.gd")
		cards_ok = cards_ok and icons.size() == 1 and icons[0].component_sources().size() == 1 and icons[0].item_id.begins_with("robot_visor_")
		cards_ok = cards_ok and card.find_children("*","Control",true,false).filter(func(node): return node.get_script() != null and node.get_script().resource_path == "res://assets/robot_portrait.gd").is_empty()
	check(cards_ok,"head category cards contain only isolated head art and no whole robot portraits")
	shop.select_slot("robot_arms")
	var arm_icon: Control = shop.cards.get_child(0).get_child(0).get_child(0).get_child(0)
	check(arm_icon.component_sources().size() == 2,"arm category shows just the selected left/right limb pair")
	var before: Dictionary = game.state.duplicate(true)
	shop.preview_part("robot_arms_loader")
	check(game.state == before and shop.robot_preview.preview_equipped.robot_arms == "robot_arms_loader","isolated part preview is assembled onto the main robot without changing progress")
	shop.turn_buttons[2].pressed.emit()
	check(shop.robot_preview.view_angle == 2,"Back button changes the actual assembled robot view")
	var rear: Array = art.oriented_pose(shop.robot_preview.preview_equipped,0,"idle",false,false,2)
	var front: Array = art.pose(shop.robot_preview.preview_equipped)
	check(rear.size() == front.size() and rear[rear.size()-1].id.begins_with("robot_core"),"back view preserves selected modules and draws the rear module visibly over the torso")
	var images_ok := true
	for direction in [1,2]:
		for id in art.regions:
			var source_image: Image = art.texture_for(id,direction).get_image()
			for side in art.directional["side" if direction == 1 else "back"][id]:
				var data: Array = art.directional["side" if direction == 1 else "back"][id][side]
				var rect := Rect2i(data[0],data[1],data[2],data[3])
				images_ok = images_ok and Rect2i(Vector2i.ZERO,source_image.get_size()).encloses(rect) and not source_image.get_region(rect).is_invisible()
	check(images_ok and art.SIDE_ATLAS.get_image().get_data() != art.BACK_ATLAS.get_image().get_data(),"all twenty-five modules have real nonempty side and rear artwork, not mirrored front sprites")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100,100)
	shop.robot_preview._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(160,100)
	shop.robot_preview._gui_input(motion)
	check(shop.robot_preview.view_angle == 3 and game.state == before,"dragging the robot display turns the directional preview without changing equipment")
	check(ResourceLoader.exists("res://assets/art/robot-workshop-v1.png") and shop.robot_preview.service_mode,"upgrade display uses the in-game workshop and maintenance lift")
	shop.select_slot("engine")
	shop.preview_part("engine_hauler")
	var parts_art: RefCounted = load("res://assets/ship_parts_art.gd").new()
	var installed: Array = parts_art.installed_parts(shop.ship_view.preview_equipped)
	check(installed.filter(func(item): return item.id == "engine_hauler").size() == 2 and game.state == before,"engine preview renders both selected detailed nacelles without buying them")
	check(parts_art.source("engine_ion") != parts_art.source("engine_hauler"),"ion and hauler cards and ship overlays use distinct mechanical art regions")
	var lamp_parts: Array = parts_art.installed_parts({"lights":"lights_teal"})
	check(lamp_parts.size() == 11 and lamp_parts[0].rect.size == Vector2(4,4),"lighting upgrades use coordinated small fixtures across the upper and lower exterior rather than neon outline strips")
	game.state.credits = 3000
	game.state.xp = 100
	game.purchase("engine")
	for id in ["robot_visor_amber","robot_arms_precision","robot_legs_strider","robot_arms_loader","engine_hauler","hull_ribs","engine_ion","robot_core_solar"]: game.buy_part(id)
	game.state.equipped.robot_visor = "robot_visor_amber"
	game.state.equipped.robot_arms = "robot_arms_precision"
	game.state.equipped.robot_legs = "robot_legs_strider"
	check(game.equipment_effects().xp_percent == 8 and game.equipment_effects().move_percent == 20,"equipped hardware contributes actual research and walking effects")
	var view: Control = shop.ship_view
	view.set_process(false)
	view.robot_position = Vector2(60,103)
	view.robot_destination = Vector2(130,103)
	view.robot_route.clear()
	view.manual_hold = 100
	view.advance_robot(0.1)
	check(view.robot_position.x > 75,"light strider legs increase actual robot travel distance per tick")
	game.state.equipped.robot_arms = "robot_arms_loader"
	game.state.equipped.engine = "engine_hauler"
	game.state.hull_integrity = 98
	game.field_repair_clock = 21
	game.advance_flight(1)
	check(game.state.hull_integrity == 99,"repair-oriented arms and engine increase actual free hull repair rate")
	game.state.equipped.hull = "hull_ribs"
	var event: Dictionary = game.resolve_encounter(0.1,0.01)
	game.apply_contact(event)
	check(game.state.hull_integrity == 98,"armor reduces an actual rare two-point impact to one point")
	game.state.equipped.engine = "engine_ion"
	var cruise_before: float = game.state.cruise_seconds
	game.advance_flight(1)
	check(game.state.cruise_seconds > cruise_before+1.1,"ion engine changes the actual shared cruise clock speed")
	game.state.equipped.robot_arms = "robot_arms_precision"
	game.state.equipped.robot_core = "robot_core_solar"
	game.state.xp = 0
	game.state.battery = 0
	game.start_session(100)
	check(game.active.effects.xp_percent == 8,"focus start snapshots the installed research bonus")
	scene.focus_dock.refresh()
	check(scene.focus_dock.reward.text.contains("+108 XP"),"focus dock displays the actual equipment-adjusted reward")
	game.state.equipped.robot_visor = "robot_visor_stock"
	game.state.equipped.robot_arms = "robot_arms_stock"
	game.active.remaining_ms = 0
	game.finish_session()
	check(game.state.xp == 108 and game.state.history[-1].xp == 108,"completion grants and records the snapshotted research bonus despite later part swaps")
	check(art.work_lamp_polygon({"robot_visor":"robot_visor_amber"},"working").size() == 3 and art.work_lamp_polygon({"robot_visor":"robot_visor_amber"},"idle").is_empty(),"headlamp equipment supplies an actual light cone only during maintenance")
	var old_xp: int = game.state.xp
	game.finish_session()
	check(game.state.xp == old_xp,"new equipment bonuses preserve once-only session rewards")
	game.state.battery = 0
	game.start_session(20)
	game.active.remaining_ms = 0
	game.finish_session()
	check(game.state.battery == 22,"solar pack increases an actual completed twenty-minute recharge from twenty to twenty-two points")
	game.load_progress()
	check(game.state.equipped.engine == "engine_ion" and game.state.history[-2].xp == 108,"equipment effects and rewarded history survive actual disk reload")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix): DirAccess.remove_absolute(game.save_path+suffix)
	print("COMPONENT WORKSHOP RESULT: ",failures," failures; assembled GPU rendering still needs player review")
	quit(0 if failures == 0 else 1)
