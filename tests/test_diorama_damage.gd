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
	game.save_path = "user://diorama_damage_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.focus_task = "Inspect ship"
	game.active = {}
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("3d")
	await process_frame
	await process_frame
	var viewer: Control = scene.ship_3d
	var art: RefCounted = viewer.diorama_art
	check(not viewer.pixel_style and viewer.viewport_container.visible,"3D tab opens real mesh rendering by default")
	var finish: ImageTexture = viewer.panel_texture(Color.WHITE)
	check(finish.get_width() == 260 and finish.get_height() == 170,"solid model uses a UV-mapped metal finish sampled from the approved pixel artwork")
	var shell: MeshInstance3D = viewer.model.get_child(0)
	var arrays: Array = shell.mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(),"hull faces carry actual surface UVs instead of a flat ship billboard")
	var camera_before: Vector3 = viewer.camera.position
	var model_before: Transform3D = viewer.model.transform
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100,100)
	viewer._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(123,111)
	viewer._gui_input(motion)
	check(viewer.camera.position.distance_to(camera_before) > 0.1 and viewer.model.transform == model_before,"drag continuously orbits actual camera around unchanged solid geometry")
	check(not is_equal_approx(viewer.yaw,-0.85) and viewer.frame_index() == 0,"small drag changes 3D angle even within a single illustrated frame")
	viewer.dragging = false
	viewer.reset_view()

	check(viewer.backdrop.get_script().resource_path == "res://assets/space_backdrop.gd","diorama uses the same space renderer as the side views")
	var before: Rect2 = viewer.background_camera()
	viewer.target = Vector3(2,1,0)
	viewer.update_camera()
	check(viewer.background_camera() == before,"panning the ship camera leaves the distant sky fixed")
	viewer.distance = 30
	check(viewer.background_camera() == before,"zoom changes the ship framing without scaling the stars")
	viewer.reset_view()
	check(viewer.background_camera().get_center().is_equal_approx(before.get_center()),"Fit restores the shared-space camera")
	check(viewer.drift_offset(30) != viewer.drift_offset(0),"cruise time produces gentle visible ship drift")
	var side: Control = load("res://assets/ship_view.gd").new()
	root.add_child(side)
	check(viewer.backdrop.cruise_planet_position(0,120) == side.backdrop.cruise_planet_position(0,120),"diorama and side-view planet fly-bys use the same cruise clock and trajectory")
	check(viewer.viewport.transparent_bg,"optional mesh viewport leaves the shared space background visible")
	var broken: Dictionary = art.damage_state(game.state.owned)
	check(broken.base == art.DAMAGED and broken.broken.size() == 3,"unrepaired starter systems select the damaged angle artwork")
	check(viewer.model.get_children().filter(func(node): return node.is_in_group("ship_engine_fault")).size() == 2,"mesh inspector also exposes both unrepaired engine faults")
	var intact: Image = art.RESTORED.get_image()
	var damaged: Image = art.DAMAGED.get_image()
	check(intact.get_size() == damaged.get_size() and damaged.get_pixel(0,0).a < 0.01,"damage atlas preserves registered dimensions and alpha transparency")
	var first: Array = viewer.pixel_frames[0]
	var region := Rect2i(first[0],first[1],first[2],first[3])
	check(intact.get_region(region).get_data() != damaged.get_region(region).get_data(),"broken artwork is a genuinely different mechanical sprite state")
	game.state.credits = 200
	game.purchase("engine")
	check("engine" not in art.damage_state(game.state.owned).broken and "cockpit" in art.damage_state(game.state.owned).broken,"engine overhaul clears engine faults while leaving unpurchased repairs broken")
	var overlays: Array = art.repair_regions(0,game.state.owned)
	check(overlays.size() == 1 and overlays[0].id == "engine","partial repair draws only the restored engine region over the broken state")
	check(viewer.model.get_children().filter(func(node): return node.is_in_group("ship_engine_fault")).is_empty(),"engine overhaul removes fault geometry from the actual mesh model")
	game.state.owned = []
	game.load_progress()
	check("engine" not in art.damage_state(game.state.owned).broken,"damage presentation follows the repair restored from disk")
	var links: RefCounted = load("res://assets/expansion_art.gd").new()
	var lab: Dictionary = game.catalog_item(game.expansion_catalog,"lab")
	var lab_link: Dictionary = links.connection(lab)
	check(lab_link.start.y <= 110 and lab_link.finish.y >= lab.bounds[1] and lab_link.width >= 18,"lab shaft spans the full hull-to-deck gap with a visible pressurized passage")
	game.state.expansions = ["lab","fabrication","habitat"]
	viewer.refresh_model()
	var connectors: Array = viewer.model.get_children().filter(func(node): return node.is_in_group("ship_deck_connector"))
	check(connectors.size() == 3,"each purchased deck receives an actual solid 3D connecting passage")
	var lab_box: AABB = connectors[0].get_aabb()
	lab_box.position += connectors[0].position
	check(lab_box.position.y < -1.4 and lab_box.end.y > -1,"3D lab shaft physically overlaps the lower room and main hull")
	var valid := true
	for frame in range(8):
		for patch in art.repair_regions(frame,["cockpit","quarters","engine"]):
			var area: Rect2 = patch.region
			valid = valid and area.position.x >= 0 and area.position.y >= 0 and area.end.x <= 1.0001 and area.end.y <= 1.0001
	check(valid,"all eight angle-specific repair patches stay inside their registered frame")
	game.purchase("cockpit")
	game.purchase("quarters")
	check(art.damage_state(game.state.owned).base == art.RESTORED,"all three restorations select the fully intact artwork")
	var worn: Dictionary = art.damage_state(game.state.owned,98)
	check(worn.hull_wear and worn.base == art.RESTORED and worn.broken.is_empty(),"minor hull scuffs do not falsely break restored systems")
	game.state.cruise_seconds = 120
	viewer.queue_redraw()
	await process_frame
	await process_frame
	check(scene.diorama_status.text.contains("restored"),"live viewer status follows the saved repair state")
	scene.queue_free()
	side.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path+suffix): DirAccess.remove_absolute(game.save_path+suffix)
	print("DIORAMA DAMAGE RESULT: ",failures," failures; assembled rendering still requires visual review")
	quit(0 if failures == 0 else 1)

