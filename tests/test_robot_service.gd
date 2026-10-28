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
	game.save_path = "user://robot_service_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Robot service checks"
	game.state.credits = 1000
	game.state.xp = 100
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("robot")
	await process_frame
	var shop: Control = scene.workshop
	var bay: Control = shop.robot_preview
	bay.set_process(false)
	var art: RefCounted = bay.art
	check(game.state.equipped.robot_paint == "robot_paint_stock" and art.finish_color({}) == Color.WHITE,"new and legacy outfits default to a single neutral metal finish")
	var palette_ok := true
	var alpha_ok := true
	for id in ["robot_visor_stock","robot_legs_boots","robot_shell_cobalt","robot_shell_loader"]:
		var img: Image = art.texture_for(id).get_image()
		alpha_ok = alpha_ok and img.get_pixel(0,0).a < 0.01
		var region: Rect2 = art.source(id,"left" if id == "robot_legs_boots" else "source")
		for y in range(int(region.position.y),int(region.end.y),9):
			for x in range(int(region.position.x),int(region.end.x),9):
				var c := img.get_pixel(x,y)
				if c.a > 0.1: palette_ok = palette_ok and absf(c.r-c.g) < 0.01 and absf(c.g-c.b) < 0.01
	check(palette_ok and alpha_ok,"actual old blue/orange and new hardware textures are neutral grayscale with preserved transparency")
	var variants := {}
	for item in game.parts:
		if item.slot in ["robot_shell","robot_visor","robot_arms","robot_legs","robot_core"]:
			if not variants.has(item.slot): variants[item.slot] = []
			variants[item.slot].append(item.id)
	var builds_ok := true
	for index in range(3125):
		var rest: int = index
		var outfit := {}
		for slot in variants:
			outfit[slot] = variants[slot][rest%5]
			rest = rest/5
		var parts: Array = art.pose(outfit)
		builds_ok = builds_ok and parts.size() == 7 and art.bounds(outfit).size.y > 20
		for part in parts: builds_ok = builds_ok and outfit.values().has(part.id)
	check(builds_ok,"all 3125 mixed hardware builds assemble their actual selected modules")
	shop.select_slot("robot_arms")
	var before: Dictionary = game.state.duplicate(true)
	shop.buy_part("robot_arms_loader")
	check(game.state == before and shop.action_buttons.robot_arms_loader.disabled,"installation is blocked before the robot is racked, including direct callback invocation")
	shop.preview_part("robot_arms_loader")
	check(game.state == before and bay.preview_equipped.robot_arms == "robot_arms_loader","unracked browsing previews parts without buying or changing progress")
	shop.rack_button.pressed.emit()
	bay.advance_service(0.4)
	check(bay.service_state == "racking" and bay.rack_progress > 0 and bay.rack_progress < 1 and not bay.service_ready(),"rack button starts a timed lift and clamp movement before installation is enabled")
	bay.advance_service(2)
	check(bay.service_ready() and not shop.action_buttons.robot_arms_loader.disabled,"installation becomes available only after the lift clamps reach their end position")
	shop.action_buttons.robot_arms_loader.pressed.emit()
	check(game.state.equipped.robot_arms == "robot_arms_loader" and game.state.credits == 915 and bay.service_state == "installing","actual install button purchases hardware once and starts its service cycle")
	var installed: Dictionary = game.state.duplicate(true)
	shop.buy_part("robot_legs_loader")
	bay.request_release()
	check(game.state == installed and bay.service_state == "installing","another installation and release are blocked while the current service cycle runs")
	bay.advance_service(1)
	shop.select_slot("robot_paint")
	check(shop.cards.get_child_count() == 6,"paint has its own category and six finish choices")
	var hardware: Array = art.pose(game.state.equipped)
	shop.preview_buttons.robot_paint_sage.pressed.emit()
	check(game.state == installed and art.finish_color(bay.preview_equipped) != art.finish_color(game.state.equipped),"paint preview changes the shared finish without spending or replacing parts")
	shop.action_buttons.robot_paint_sage.pressed.emit()
	check(game.state.equipped.robot_paint == "robot_paint_sage" and game.state.equipped.robot_arms == "robot_arms_loader" and art.pose(game.state.equipped) == hardware,"buying paint changes color independently of all hardware and geometry")
	bay.advance_service(1)
	shop.select_slot("robot_legs")
	shop.buy_part("robot_legs_loader")
	check(game.state.equipped.robot_paint == "robot_paint_sage" and game.state.equipped.robot_legs == "robot_legs_loader","installing different legs retains the chosen whole-robot finish")
	bay.advance_service(1)
	game.load_progress()
	check(game.state.equipped.robot_paint == "robot_paint_sage" and game.state.equipped.robot_arms == "robot_arms_loader" and game.state.equipped.robot_legs == "robot_legs_loader","hardware and independent finish survive a real disk reload together")
	var path: String = game.save_path
	game.save_path = "res://nonexistent_service_directory/save.json"
	before = game.state.duplicate(true)
	shop.buy_part("robot_paint_crimson")
	check(game.state == before and bay.service_ready(),"failed finish persistence rolls back money and equipment without starting installation")
	game.save_path = path
	shop.rack_button.pressed.emit()
	bay.advance_service(1)
	check(bay.service_state == "free" and bay.rack_progress == 0 and not bay.service_ready(),"release button retracts the clamps and disables further installs")
	game.state.equipped.erase("robot_paint")
	game.save_progress()
	game.load_progress()
	check(game.state.equipped.robot_paint == "robot_paint_stock" and game.state.equipped.robot_legs == "robot_legs_loader","older saves gain neutral finish without losing owned hardware")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("ROBOT SERVICE RESULT: ",failures," failures; rendered lift appearance requires visual review")
	quit(0 if failures == 0 else 1)

