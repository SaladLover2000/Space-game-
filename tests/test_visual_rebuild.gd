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
	game.save_path = "user://visual_rebuild_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Visual behavior checks"
	game.active = {}
	var art: RefCounted = load("res://assets/robot_art.gd").new()
	check(art.texture_for("robot_shell_stock") == art.WHITE_ATLAS and art.texture_for("robot_shell_loader") == art.WHITE_ATLAS_V2,"all front robot hardware renders authored cream ceramic art instead of desaturated metal")
	var a: Array = art.pose({},3,"working")
	var b: Array = art.pose({},4,"working")
	check(a.filter(func(piece): return piece.get("segment","") == "forearm").size() == 2 and a.filter(func(piece): return piece.get("segment","") == "hand").size() == 2,"working poses contain separate forearm and wrist/hand joints")
	var movement := false
	for index in range(a.size()):
		if a[index].get("segment","") == "forearm": movement = movement or not is_equal_approx(a[index].rotation,b[index].rotation)
	check(movement and art.tool_position({},3) != art.tool_position({},4),"independent elbow motion moves the actual tool attachment point")
	check(not art.work_action(1).holding_tool and art.work_action(4).holding_tool and not art.work_action(7.5).holding_tool,"work cycle actually collects, uses and returns its tool")
	var seated: Array = art.oriented_pose({},2,"working",false,true,2)
	check(seated.filter(func(piece): return piece.id == "robot_legs_stock").size() == 4,"rear seated pose keeps separate bent thigh/shin sections")
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("ship")
	var view: Control = scene.ship_view
	view.set_process(false)
	view.follow_robot("engine")
	view.door_open.bridge = true
	view.door_open.engine = true
	view.door_progress.bridge = 1
	view.door_progress.engine = 1
	for step in range(4): view.advance_robot(10)
	check(view.expression() == "working","commanding the engine room starts actual maintenance upon arrival without waiting for the idle timeout")
	scene._process(0)
	check(not is_instance_valid(scene.robot_mood) or scene.robot_mood.text.contains("Working"),"working activity has a valid live status label")
	scene.show_page("bridge")
	var bridge: Control = scene.bridge_view
	bridge.set_mode("navigation")
	check(bridge.actor_state().seated and bridge.actor_state().angle == 2 and bridge.actor_state().scale >= bridge.size.y/60,"navigation actually seats a large rear-facing robot at the pilot controls")
	check(bridge.background_texture() == bridge.DAMAGED,"unrepaired bridge uses visibly damaged consoles, hanging cables and ruptured fittings")
	game.state.owned.append("cockpit")
	check(bridge.background_texture() == bridge.BACKPLATE,"bridge repair switches its actual background to restored equipment")
	bridge.set_mode("diagnostics")
	check(not bridge.actor_state().seated and bridge.actor_state().angle == 1 and bridge.actor_state().mood == "working","diagnostics turns a full-size articulated robot toward the service console")
	scene.show_page("robot")
	var bay: Control = scene.workshop.robot_preview
	bay.set_process(false)
	bay.request_rack()
	bay.advance_service(2)
	check(bay.service_ready() and bay.maintenance.hoist_lift(bay.rack_progress) == 8,"chain hoist lifts the robot eight world units clear of the floor before installation")
	check(bay.maintenance.SOURCES.has("chain") and bay.maintenance.SOURCES.has("spreader") and bay.maintenance.SOURCES.has("winch"),"lift assembles actual chain, winch and spreader sprites instead of the old flat cage")
	bay.request_release()
	bay.advance_service(1)
	check(bay.maintenance.hoist_lift(bay.rack_progress) == 0,"release lowers the robot back onto the workshop floor")
	var original: Image = art.texture_for("robot_shell_stock").get_image()
	var painted: Image = art.finished_texture("robot_shell_stock",{"robot_paint":"robot_paint_crimson"}).get_image()
	var changed := 0
	var cream := 0
	var dark_unchanged := 0
	var rect: Rect2 = art.source("robot_shell_stock")
	for y in range(int(rect.position.y),int(rect.end.y),2):
		for x in range(int(rect.position.x),int(rect.end.x),2):
			var old := original.get_pixel(x,y)
			var next := painted.get_pixel(x,y)
			if old.a < 0.1: continue
			if old != next: changed += 1
			if next.r > 0.75 and next.g > 0.7 and next.b > 0.55: cream += 1
			if old.r < 0.25 and old.g < 0.25 and old.b < 0.25 and old == next: dark_unchanged += 1
	check(changed > 100 and cream > 100 and dark_unchanged > 100,"crimson paint creates distinct colored armor panels while retaining ivory panels and dark unpainted mechanisms")
	var ship: RefCounted = load("res://assets/pixel_ship_art.gd").new()
	check(ship.skin_texture(ship.EXTERIOR,{"wings":"wings_solar"},true) == ship.CORE_EXTERIOR,"upgraded fins select a genuinely wingless hull instead of overlaying baked stock wings")
	var core: Image = ship.CORE_EXTERIOR.get_image()
	var stock: Image = ship.EXTERIOR.get_image()
	check(core.get_pixel(1300,180).a < 0.1 and stock.get_pixel(1300,180).a > 0.5 and core.get_pixel(1170,850).a < 0.1,"original top and bottom fin silhouettes are absent from the replacement hull")
	var parts: RefCounted = load("res://assets/ship_parts_art.gd").new()
	var fins: Array = parts.installed_parts({"wings":"wings_swept"})
	check(fins.size() == 2 and fins[1].get("flip_y",false),"replacement recipe attaches a top fin and a correctly mirrored lower fin")
	var hull_paint: Image = ship.skin_texture(ship.EXTERIOR,{"paint":"paint_copper"},true).get_image()
	var zones := [0,0,0]
	for y in range(350,740,4):
		for x in range(50,1460,4):
			if stock.get_pixel(x,y).a > 0.5 and stock.get_pixel(x,y) != hull_paint.get_pixel(x,y): zones[mini(2,x/512)] += 1
	check(zones[0] > 50 and zones[1] > 50 and zones[2] > 50,"ship paint changes armor across nose, mid hull and aft hull rather than one pasted patch")
	check(parts.installed_parts({"paint":"paint_copper"}).is_empty(),"paint upgrade no longer adds a rectangular surface overlay")
	var doors: RefCounted = load("res://assets/interior_art.gd").new()
	check(doors.maintenance.ATLAS.get_image().get_pixel(0,0).a < 0.1,"blocking hatch visuals use the matching transparent industrial door atlas")
	check(scene.find_children("*","Button",true,false).filter(func(node): return node.text == "Drift").is_empty(),"obsolete Drift navigation is absent")
	scene.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix): DirAccess.remove_absolute(game.save_path+suffix)
	print("VISUAL REBUILD RESULT: ",failures," failures; GPU appearance still needs player review")
	quit(0 if failures == 0 else 1)

