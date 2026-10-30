extends SceneTree
var destination: String
var art: RefCounted
var serial: int = 0
var saved_textures: Dictionary = {}
func rect(value: Rect2) -> Array:
	return [value.position.x,value.position.y,value.size.x,value.size.y]
func points(value: PackedVector2Array) -> Array:
	var result: Array = []
	for point in value: result.append([point.x,point.y])
	return result
func save_texture(texture: Texture2D, name: String) -> String:
	if saved_textures.has(texture.get_instance_id()): return saved_textures[texture.get_instance_id()]
	saved_textures[texture.get_instance_id()] = name+".png"
	texture.get_image().save_png(destination+"/"+name+".png")
	return name+".png"
func actor(feet: Vector2, scale_factor: float, time: float, mood: String, walking: bool, seated: bool, angle: int, targets: Dictionary = {}) -> Dictionary:
	var pieces: Array = []
	for piece in art.oriented_pose({},time,mood,walking,seated,angle,targets):
		serial += 1
		var vertices: PackedVector2Array = art.vertices(piece)
		if angle == 3:
			for i in range(vertices.size()): vertices[i].x = -vertices[i].x
		pieces.append({"texture":save_texture(art.finished_texture(piece.id,{},angle,mood),"piece_"+str(serial)),"source":rect(piece.source),"points":points(vertices)})
	return {"feet":[feet.x,feet.y],"scale":scale_factor,"pieces":pieces}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	destination = OS.get_cmdline_user_args()[0]
	var game := root.get_node("Game")
	game.set_process(false)
	game.state = game.defaults()
	game.state.owned = ["engine","quarters","cockpit"]
	game.state.robot_condition = 100
	game.state.engine_condition = 100
	game.state.robot_light = "blue"
	game.state.engine_modules = {"pump":2,"injector":2,"cooling":2,"nozzle":2}
	art = load("res://assets/robot_art.gd").new()
	var frames: Array = []
	var size := Vector2(900,540)
	var bridge: Control = load("res://ui/bridge_view.gd").new()
	root.add_child(bridge)
	bridge.size = size
	bridge.set_process(false)
	var sky: Dictionary = bridge.window_scene(30)
	var planets: Array = []
	for planet in sky.planets: planets.append({"rect":rect(planet.rect),"polygon":points(planet.polygon),"texture":save_texture(bridge.space.planets[planet.index],"planet_"+str(planet.index))})
	var star_points: Array = []
	for point in sky.stars: star_points.append([point.x,point.y])
	var state: Dictionary = bridge.actor_state()
	frames.append({"name":"Bridge / hands at the keyboard","kind":"bridge","background":save_texture(bridge.background_texture(),"bridge"),"sky":save_texture(bridge.space.nebula,"sky"),"corners":points(sky.corners),"stars":star_points,"planets":planets,"keyboard":rect(bridge.keyboard_layout()),"actors":[actor(state.feet,state.scale,1,"typing",false,true,2)]})
	var charging: Control = load("res://ui/charging_dock_view.gd").new()
	root.add_child(charging)
	charging.size = size
	charging.set_process(false)
	state = charging.actor_state()
	frames.append({"name":"Charging / planted on cradle, optics off","kind":"charging","background":save_texture(charging.cabin.quarters_texture(game.state.owned),"quarters"),"actors":[actor(state.feet,state.scale,3,"charging",false,false,0)]})
	frames.append({"name":"Walking / connected hips, knees and feet","kind":"walk","background":save_texture(load("res://assets/art/robot-workshop-v1.png"),"workshop"),"actors":[actor(Vector2(180,470),8,0.1,"idle",true,false,0),actor(Vector2(450,470),8,0.3,"idle",true,false,1),actor(Vector2(720,470),8,0.55,"idle",true,false,1)]})
	var engine: Control = load("res://ui/engine_bay_view.gd").new()
	root.add_child(engine)
	engine.set_process(false)
	engine.size = size
	var source_texture := save_texture(engine.machinery.ATLAS,"engine_atlas")
	for task in range(5):
		var index := mini(task,2)
		engine.choose_task(index)
		engine.actor_x = engine.WORK_X[index]
		engine._process(0)
		engine.work_clock = 4.0 if index == 2 else 2.5
		engine.sorted_count = 1 if index == 2 else 0
		if task >= 3:
			engine.begin_assembly()
			if task == 3: engine.assembly_slots = {"pump":true,"injector":true}
			else: engine.assembly_slots = {"pump":true,"injector":true,"cooling":true,"nozzle":true}
		state = engine.actor_state()
		var assemblies: Array = []
		for piece in engine.machinery.layout(game.state.engine_modules,100,true):
			if task >= 3 and not engine.assembly_slots.has(piece.id): continue
			assemblies.append({"id":piece.id,"rect":rect(Rect2(piece.rect.position*size,piece.rect.size*size)),"source":rect(piece.source)})
		var supports: Array = []
		for support in engine.machinery.support_layout(size,game.state.engine_modules,100,true): supports.append({"rect":rect(support.rect),"floor":support.floor,"ceiling":support.ceiling})
		var sorting: Dictionary = engine.sorting_state()
		var sort_parts: Array = []
		for piece in sorting.pieces: sort_parts.append({"id":piece.id,"position":[piece.position.x,piece.position.y],"sorted":piece.sorted})
		var hand: Vector2 = art.tool_position({},engine.work_clock,state.angle,false,state.mood,state.targets)
		if state.angle == 3: hand.x = -hand.x
		hand = state.feet+hand*state.scale
		var trays: Array = []
		if task >= 3:
			for part in engine.assembly_tray(): trays.append({"id":part.id,"rect":rect(part.rect),"source":rect(engine.machinery.source(part.id,3))})
		var label: String = ["Inspection / reach toward the controls","Pump seal / articulated torque check","Sorting / carried part and filled bins","Assembly / fit owned parts into sockets","Assembled engine / supported hardware"][task]
		var actors: Array = [actor(state.feet,state.scale,engine.work_clock,state.mood,false,false,state.angle,state.targets)] if task < 3 else []
		frames.append({"name":label,"kind":"engine","task":task,"background":save_texture(engine.background_texture(),"engine_room"),"assemblies":assemblies,"tray_parts":trays,"supports":supports,"atlas":source_texture,"actors":actors,"sort_parts":sort_parts,"held":sorting.held,"hand":[hand.x,hand.y],"scale":state.scale})
	var hull: RefCounted = load("res://assets/ship_parts_art.gd").new()
	var skin: RefCounted = load("res://assets/pixel_ship_art.gd").new()
	var plates: Array = []
	for plate in hull.armor_plates("hull_ribs"): plates.append(points(plate.polygon))
	var exterior_regions: Array = []
	for region in skin.skin_regions({"engine":"engine_hauler"}): exterior_regions.append(rect(region))
	var exterior_engines: Array = []
	for part in hull.installed_parts({"engine":"engine_hauler"}):
		if part.id == "engine_hauler": exterior_engines.append({"rect":rect(part.rect),"source":rect(hull.source(part.id))})
	var mounts: Array = []
	for mount in hull.engine_mount_geometry({"engine":"engine_hauler"}): mounts.append({"rect":rect(mount.rect),"color":mount.color})
	frames.append({"name":"Hull plates / bolted replacement engine pods","mounts":mounts,"skin_regions":exterior_regions,"engine_parts":exterior_engines,"engine_atlas":save_texture(hull.ATLAS,"ship_components"),"kind":"hull","background":save_texture(skin.EXTERIOR,"ship"),"plates":plates,"actors":[]})
	var file := FileAccess.open(destination+"/visual-actions.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"size":[size.x,size.y],"frames":frames}))
	file.close()
	quit()
