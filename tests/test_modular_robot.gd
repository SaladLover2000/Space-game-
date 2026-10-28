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

func part_for(parts: Array, id: String, occurrence: int = 0) -> Dictionary:
	for part in parts:
		if part.id == id:
			if occurrence == 0:
				return part
			occurrence -= 1
	return {}

func run() -> void:
	var art := preload("res://assets/robot_art.gd").new()
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://modular_robot_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.active = {}
	var original := art.bounds({})
	var broad := {"robot_shell":"robot_shell_copper", "robot_arms":"robot_arms_utility", "robot_legs":"robot_legs_boots", "robot_visor":"robot_visor_wide"}
	var tall := {"robot_shell":"robot_shell_cobalt", "robot_arms":"robot_arms_precision", "robot_legs":"robot_legs_strider", "robot_visor":"robot_visor_amber"}
	check(art.bounds(broad).size.x > original.size.x*1.2, "heavy chassis and arms produce a genuinely wider assembled robot")
	check(art.bounds(tall).size.y > original.size.y*1.2, "survey chassis and legs produce a genuinely taller assembled robot")
	var base_pose: Array = art.pose({})
	var longer_legs: Array = art.pose({"robot_legs":"robot_legs_strider"})
	check(part_for(longer_legs,"robot_shell_stock").rect.position.y < part_for(base_pose,"robot_shell_stock").rect.position.y and part_for(longer_legs,"robot_visor_stock").rect.position.y < part_for(base_pose,"robot_visor_stock").rect.position.y, "longer legs raise the existing torso and head rather than replacing a whole-body picture")
	var broad_pose: Array = art.pose({"robot_shell":"robot_shell_copper"})
	check(part_for(broad_pose,"robot_arms_stock",1).rect.position.x > part_for(base_pose,"robot_arms_stock",1).rect.position.x, "a wider chassis moves unchanged service arms to the new shoulder anchors")
	check(art.clearance(broad) > art.clearance({}), "wide equipment requires more real clearance at closed hatches")
	var image: Image = art.ATLAS.get_image()
	check(image.get_size() == Vector2i(1536,1024) and image.get_pixel(0,0).a < 0.01, "detailed parts atlas has the calibrated size and transparent background")
	var atlas_ok := true
	var regions_count := 0
	for id in art.regions:
		for side in art.regions[id]:
			var region: Rect2 = art.source(id,side)
			atlas_ok = atlas_ok and Rect2(Vector2.ZERO,Vector2(image.get_size())).encloses(region) and not image.get_region(Rect2i(region)).is_invisible()
			regions_count += 1
	check(atlas_ok and regions_count == 21, "all fifteen equipment IDs map to twenty-one nonempty isolated component regions")
	var variants := {
		"robot_shell":["stock","copper","cobalt"],"robot_visor":["stock","wide","amber"],
		"robot_arms":["stock","utility","precision"],"robot_legs":["stock","boots","strider"],"robot_core":["stock","beacon","solar"]}
	var combinations_ok := true
	for index in range(243):
		var remaining: int = index
		var outfit := {}
		for slot in variants:
			outfit[slot] = slot + "_" + variants[slot][remaining % 3]
			remaining = remaining / 3
		var pieces: Array = art.pose(outfit)
		combinations_ok = combinations_ok and pieces.size() == 7
		for id in outfit.values():
			combinations_ok = combinations_ok and not part_for(pieces,id).is_empty()
		var legs: Dictionary = part_for(pieces,outfit.robot_legs)
		var body: Dictionary = part_for(pieces,outfit.robot_shell)
		var head: Dictionary = part_for(pieces,outfit.robot_visor)
		combinations_ok = combinations_ok and is_zero_approx(legs.rect.end.y) and body.rect.end.y >= legs.rect.position.y and head.rect.end.y >= body.rect.position.y
		combinations_ok = combinations_ok and Rect2(-28,-50,56,54).encloses(art.bounds(outfit))
	check(combinations_ok, "all 243 mixed outfits use the chosen modules, meet at neck and hip anchors, stand on the deck and fit the shared portrait stage")
	check(art.pose({"robot_shell":"unknown"}) == base_pose, "invalid visual module ID falls back to the stock chassis")
	game.state.credits = 1000
	game.state.xp = 100
	for slot in broad:
		game.buy_part(broad[slot])
	game.load_progress()
	check(art.bounds(game.state.equipped).size.is_equal_approx(art.bounds(broad).size), "purchased modular body dimensions survive disk reload")
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("shop")
	var shop: Control = scene.workshop
	shop.select_slot("robot_legs")
	var before: Dictionary = game.state.duplicate(true)
	shop.preview_buttons.robot_legs_strider.pressed.emit()
	check(art.bounds(shop.robot_preview.preview_equipped).size.y > art.bounds(game.state.equipped).size.y and game.state == before, "actual shop preview shows taller legs on the current body without charging or equipping")
	scene.show_page("interior")
	var view: Control = scene.ship_view
	view.set_process(false)
	view.robot_position = Vector2(143,103)
	view.door_open.engine = false
	view.door_progress.engine = 0
	view.follow_robot("engine")
	view.advance_robot(10)
	check(is_equal_approx(view.robot_position.x,172-art.clearance(game.state.equipped)), "a closed hatch stops the upgraded body at its actual outside edge")
	view.toggle_door("engine")
	view.door_progress.engine = 1
	view.advance_robot(10)
	check(view.robot_position == Vector2(205,103), "wide upgraded robot resumes the pending room route after the hatch opens")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix):
			DirAccess.remove_absolute(game.save_path+suffix)
	print("MODULAR ROBOT RESULT: ", failures, " failures; composition checks are not a rendered game review")
	quit(0 if failures == 0 else 1)
