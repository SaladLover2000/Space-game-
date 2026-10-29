extends SceneTree
var failures: int = 0
var game: Node

func check(value: bool, description: String) -> void:
	if value: print("PASS: ",description)
	else:
		failures += 1
		push_error(description)

func put(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://structure_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.state.credits = 5000
	game.state.xp = 1000
	game.state.owned = ["engine","quarters","hull_shielded","antenna_radar"]
	game.state.engine_condition = 100
	game.state.engine_modules = {"pump":3,"injector":3,"cooling":3,"nozzle":3}
	game.state.research = ["navigation_patch"]
	game.state.equipped.hull = "hull_shielded"
	game.state.equipped.antenna = "antenna_radar"
	game.state.cruise_seconds = 200.0
	check(game.save_progress(),"baseline isolated snapshot persists")
	check(game.set_setting("sound",false),"settings persist through authoritative API")
	game.load_progress()
	check(not game.state.sound,"settings survive actual disk reload")
	check(not game.set_setting("credits",true),"settings API rejects progress fields")
	var save_path: String = game.save_path
	game.save_path = "user://missing-structure-directory/save.json"
	check(not game.set_setting("sound",true) and not game.state.sound,"failed setting save rolls state back")
	game.state.docked_station = "station_0"
	check(not game.undock_station() and game.state.docked_station == "station_0","failed undock save returns failure and restores port")
	game.save_path = save_path
	game.state.docked_station = ""
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_page("settings")
	var toggle: CheckButton
	for candidate in buttons(scene.content):
		if candidate is CheckButton and candidate.text == "Play completion chime": toggle = candidate
	game.save_path = "user://missing-structure-directory/save.json"
	toggle.button_pressed = true
	check(not toggle.button_pressed and not game.state.sound,"real toggle callback restores visual setting after save failure")
	game.state.focus_task = "Previously saved task"
	scene.focus_dock.task.text = "New unsaved draft"
	check(not scene.focus_dock.flush_task() and game.state.focus_task == "Previously saved task" and scene.focus_dock.task.text == "New unsaved draft","failed focus-task save restores state and retains the editable draft")
	scene.focus_dock.start_button.pressed.emit()
	check(game.active.is_empty(),"Start callback stops when saving the task fails")
	game.save_path = save_path
	check(scene.focus_dock.flush_task() and game.state.focus_task == "New unsaved draft","task draft can be saved after storage recovers")
	var wave: AudioStream = scene.sound_player.stream
	scene.on_completed(0,0)
	scene.on_completed(0,0)
	check(scene.sound_player.stream == wave and wave != null,"completion reuses one built chime resource")
	var focus: Control = scene.focus_dock
	for page in scene.PAGE_SCRIPTS:
		scene.show_page(page)
		await process_frame
		scene.show_page("stats")
		await process_frame
		check(scene.ship_view == null and scene.workshop == null and scene.charging_view == null and scene.engine_panel == null and scene.bridge_view == null and scene.robot_name_edit == null,"page teardown releases controls: "+page)
	check(scene.focus_dock == focus and is_instance_valid(focus),"page teardown preserves shared focus dock")
	game.balance.ports.station.price = 17
	game.balance.ports.station.level = 2
	game.balance.ports.planet.price = 23
	game.balance.ports.planet.level = 2
	game.balance.quarters_decor.terrarium = 7
	game.balance.hull_patch_price = 3
	check(game.station_contact().price == 17 and game.station_contact().level == 2,"station contact reads modified balance data")
	var before: int = game.state.credits
	check(game.dock_station().ok and game.state.credits == before-17,"station purchase charges configured price")
	game.undock_station()
	game.state.cruise_seconds = 200
	check(game.planet_contact().price == 23,"planet contact reads modified balance data")
	before = game.state.credits
	check(game.land_planet().ok and game.state.credits == before-23,"landing charges configured price")
	game.undock_station()
	before = game.state.credits
	check(game.buy_quarters_decor("terrarium").ok and game.state.credits == before-7,"decor purchase reads configured price")
	game.state.hull_integrity = 90
	before = game.state.credits
	check(game.patch_hull().ok and game.state.credits == before-3,"hull repair reads configured price")
	scene.show_page("stations")
	var station_button := false
	for candidate in buttons(scene.content): station_button = station_button or candidate.text == "Request docking / 17 credits"
	check(station_button,"actual station page shows authoritative price")
	scene.show_page("planet")
	var planet_button := false
	for candidate in buttons(scene.content): planet_button = planet_button or candidate.text == "Request planetary entry / 23 credits"
	check(planet_button,"actual planetary page shows authoritative price")
	var original: Dictionary = game.equipment_effects()
	game.state.equipped.wings = "wings_swept"
	check(game.equipment_effects().cruise_percent == original.cruise_percent+8,"effects cache notices changed equipment")
	game.load_progress()
	check(game.equipment_effects().cruise_percent == original.cruise_percent,"effects cache notices disk reload")
	check(not game.effect_lines({"slot":"hull","effects":{"typo":4}}).is_empty(),"unknown effect label is handled without a crash")
	var fixture := "user://catalog_fixture"
	DirAccess.make_dir_recursive_absolute(fixture)
	for filename in DirAccess.get_files_at("res://data"):
		if filename.get_extension() == "json": DirAccess.copy_absolute("res://data/"+filename,fixture+"/"+filename)
	var catalog := preload("res://scripts/services/catalog_loader.gd").new()
	put(fixture+"/ship_parts.json",'[{"id":"bad","name":"Bad","description":"Bad","price":0,"xp":0,"slot":"hull","effects":{"typo":2}}]')
	check(catalog.load_all(fixture).is_empty() and "typo" in catalog.error_message and "bad" in catalog.error_message,"catalog reports invalid effect with file and item context")
	put(fixture+"/ship_parts.json",'{invalid')
	check(catalog.load_all(fixture).is_empty() and "line" in catalog.error_message and "ship_parts" in catalog.error_message,"malformed JSON has a clear filename and line diagnostic")
	game.state.custom_decal = "C:/outside.png"
	game.state.graffiti = "custom"
	game.save_progress()
	game.load_progress()
	check(game.state.custom_decal.is_empty() and game.state.graffiti == "none","unsafe decal path is cleared without losing progress")
	check(not game.safe_decal_path("user://decals/../art_escape.png"),"decal traversal is rejected")
	var image := Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var source := "user://source.png"
	image.save_png(source)
	check(game.import_decal(source).ok,"first local PNG imports successfully")
	var first: String = game.state.custom_decal
	check(game.import_decal(source).ok,"replacement local PNG imports successfully")
	var second: String = game.state.custom_decal
	check(FileAccess.file_exists(first) and FileAccess.file_exists(second),"replacement retains artwork owned by recovery backup")
	game.save_progress()
	check(not FileAccess.file_exists(first) and FileAccess.file_exists(second),"unreferenced artwork is cleaned after backup rotates")
	game.save_path = "user://missing-structure-directory/save.json"
	check(not game.import_decal(source).ok and game.state.custom_decal == second and FileAccess.file_exists(second),"failed decal save preserves previously installed artwork")
	game.save_path = save_path
	scene.queue_free()
	await process_frame
	print("RESULT: ",failures," failures")
	quit(1 if failures else 0)
