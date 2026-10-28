extends Control
## Real mesh-based inspector: mouse input changes the camera, never the ship.
const DioramaArt = preload("res://assets/diorama_art.gd")
const SpaceBackdrop = preload("res://assets/space_backdrop.gd")
var diorama_art := DioramaArt.new()
var armor_texture: ImageTexture
var backdrop: RefCounted
const MODULE_ATLAS = preload("res://assets/art/expansion-modules-v1.png")
const PIXEL_ATLAS = preload("res://assets/art/ship-pixel-angles-v2.png")
var pixel_frames: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_angle_frames.json"))
var pixel_style: bool = false
var viewport_container: SubViewportContainer
var viewport: SubViewport
var model: Node3D
var camera: Camera3D
var yaw: float = -0.85
var pitch: float = 0.35
var distance: float = 17.0
var target := Vector3.ZERO
var dragging: bool = false
var previous_mouse := Vector2.ZERO
var model_key: String = ""
var mesh_count: int = 0
var scanner: MeshInstance3D

func material(color: String, glow: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.metallic = 0.6 if not glow else 0.0
	result.roughness = 0.75
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if not glow:
		result.albedo_texture = panel_texture(Color(color))
	if glow:
		result.emission_enabled = true
		result.emission = Color(color)
		result.emission_energy_multiplier = 1.8
	return result

func panel_texture(_base: Color) -> ImageTexture:
	# Reuse the approved pixel artwork as an actual UV-mapped metal finish.
	# This is a surface texture on solid meshes, not a camera-facing ship image.
	if armor_texture == null:
		var image: Image = preload("res://assets/art/ship-exterior-v1.png").get_image()
		armor_texture = ImageTexture.create_from_image(image.get_region(Rect2i(640,445,260,170)))
	return armor_texture

func add_mesh(mesh: Mesh, position: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = position
	instance.rotation = rotation
	model.add_child(instance)
	mesh_count += 1
	return instance

func box(position: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	add_mesh(mesh,position,mat)

func cylinder(position: Vector3, radius: float, length: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 20
	add_mesh(mesh,position,mat,Vector3(0,0,PI/2))

func prism(points: PackedVector2Array, depth: float, position: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(points)
	for side in [-1,1]:
		for i in range(0,triangles.size(),3):
			for index in ([0,1,2] if side == 1 else [2,1,0]):
				var p: Vector2 = points[triangles[i+index]]
				surface.set_uv(Vector2((p.x+5)*0.6,(p.y+1)*0.6))
				surface.add_vertex(Vector3(p.x,p.y,side*depth/2))
	for i in range(points.size()):
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i+1)%points.size()]
		for vertex in [Vector3(a.x,a.y,-depth/2),Vector3(b.x,b.y,-depth/2),Vector3(b.x,b.y,depth/2),Vector3(a.x,a.y,-depth/2),Vector3(b.x,b.y,depth/2),Vector3(a.x,a.y,depth/2)]:
			surface.set_uv(Vector2(vertex.x*0.6,vertex.z*0.6+vertex.y*0.6))
			surface.add_vertex(vertex)
	surface.generate_normals()
	add_mesh(surface.commit(),position,mat,rotation)

func hull_shell(steel: Material, bright: Material, dark: Material, glass: Material) -> void:
	# Octagonal sections make the bow taper in width AND height, with real canopy faces.
	var rings := [Vector3(-5,0.10,0.12),Vector3(-3.4,0.72,0.76),Vector3(-1.5,1.02,1.2),Vector3(2,1.05,1.2),Vector3(4,0.74,1.02),Vector3(5,0.40,0.8)]
	var perimeter := [Vector2(-0.7,-1),Vector2(0.7,-1),Vector2(1,-0.65),Vector2(1,0.65),Vector2(0.7,1),Vector2(-0.7,1),Vector2(-1,0.65),Vector2(-1,-0.65)]
	for ring in range(rings.size()-1):
		for side in range(8):
			var next := (side+1)%8
			var vertices := PackedVector3Array()
			for entry in [[ring,side],[ring+1,side],[ring+1,next],[ring,next]]:
				var section: Vector3 = rings[entry[0]]
				var point: Vector2 = perimeter[entry[1]]
				vertices.append(Vector3(section.x,point.y*section.y,point.x*section.z))
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var uv := [Vector2(0,0),Vector2(2,0),Vector2(2,1),Vector2(0,1)]
			for index in [0,1,2,0,2,3]:
				surface.set_uv(uv[index])
				surface.add_vertex(vertices[index])
			surface.generate_normals()
			var canopy: bool = ring in [0,1] and side in [3,4,5]
			add_mesh(surface.commit(),Vector3.ZERO,glass if canopy else bright if side in [3,4,5] else dark if side == 0 else steel)
			if canopy:
				# Metal canopy mullions are cylinders between real 3D points.
				for edge in [[0,1],[1,2]]:
					beam(vertices[edge[0]],vertices[edge[1]],0.045,bright)

func beam(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	var node := add_mesh(mesh,(a+b)/2,mat)
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func _ready() -> void:
	custom_minimum_size = Vector2(600,460)
	backdrop = SpaceBackdrop.new()
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var container := SubViewportContainer.new()
	viewport_container = container
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.visible = not pixel_style
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(960,540)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.background_color = Color("070d20")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a3b9d0")
	environment.ambient_light_energy = 0.7
	environment_node.environment = environment
	world.add_child(environment_node)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-38,-40,0)
	key_light.light_color = Color("dcf0ff")
	key_light.light_energy = 1.6
	world.add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(30,130,0)
	rim.light_color = Color("679ed0")
	rim.light_energy = 0.7
	world.add_child(rim)
	model = Node3D.new()
	world.add_child(model)
	camera = Camera3D.new()
	camera.fov = 42
	camera.current = true
	world.add_child(camera)
	Game.changed.connect(refresh_model)
	refresh_model()
	update_camera()

func refresh_model() -> void:
	var key := str(Game.state.equipped)+str(Game.state.expansions)+str(Game.state.research)+str(Game.state.owned)+str(Game.state.engine_condition)+str(Game.state.hull_integrity)
	if key == model_key:
		return
	model_key = key
	for child in model.get_children():
		model.remove_child(child)
		child.queue_free()
	mesh_count = 0
	var steel := material("8296a5")
	var bright := material("c8d3cf")
	var dark := material("263649")
	var paint := material("a56c50" if Game.state.equipped.paint == "paint_copper" else "2c5181")
	var cyan := material("66e6e3",true)
	var engine_light := cyan if Game.state.engine_condition >= 25 else material("425767")
	var brass := material("bd9766")
	hull_shell(steel,bright,dark,material("2b7e9b"))
	for side in [-1,1]:
		prism(PackedVector2Array([Vector2(-4.4,0.1),Vector2(-3,0.95),Vector2(-1.5,0.9),Vector2(-1.5,0.25)]),0.05,Vector3(0,0,side*1.22),material("2b7e9b"))
		prism(PackedVector2Array([Vector2(-0.7,0),Vector2(2.4,2.7),Vector2(3.5,2.7),Vector2(2.9,-0.1)]),0.2,Vector3(0,-0.45,side*1.2),paint,Vector3(side*PI/2,0,0))
		prism(PackedVector2Array([Vector2(0.5,0),Vector2(2.7,2.3),Vector2(3.5,2.3),Vector2(3.5,0)]),0.18,Vector3(0,0.8,side*0.9),paint)
		for x in range(-2,4):
			box(Vector3(x,0.1,side*1.23),Vector3(0.5,0.32,0.07),dark)
			box(Vector3(x,0.15,side*1.28),Vector3(0.32,0.12,0.04),cyan)
			box(Vector3(x,0.72,side*1.1),Vector3(0.65,0.08,0.08),bright)
		for x in range(-1,4):
			box(Vector3(x,-0.6,side*1.22),Vector3(0.65,0.1,0.06),brass)
		var engine_radius := 0.68 if Game.state.equipped.engine == "engine_hauler" else 0.55
		cylinder(Vector3(4.8,-0.1,side*1.0),engine_radius,1.6,dark)
		for i in range(7):
			cylinder(Vector3(4.2+i*0.18,-0.1,side*1.0),engine_radius+0.05,0.06,bright)
		cylinder(Vector3(5.65,-0.1,side*1.0),engine_radius*0.75,0.06,engine_light)
		if "engine" in Game.state.owned:
			cylinder(Vector3(6.3,-0.1,side*1.0),engine_radius*0.42,1.2,material("d1fcff",true))
		else:
			var fault := BoxMesh.new()
			fault.size = Vector3(0.7,0.5,0.08)
			var panel := add_mesh(fault,Vector3(4.3,-0.7,side*1.25),brass,Vector3(0.2,0,0.35))
			panel.add_to_group("ship_engine_fault")
			box(Vector3(4.2,-0.2,side*1.3),Vector3(0.15,0.9,0.08),brass)
		if Game.state.equipped.wings == "wings_solar":
			for i in range(3):
				box(Vector3(1.0+i*0.6,-0.3,side*2.7),Vector3(0.5,0.07,1.3),material("315d9f"))
	if "cockpit" not in Game.state.owned:
		var crack := BoxMesh.new()
		crack.size = Vector3(0.7,0.025,0.02)
		add_mesh(crack,Vector3(-3,0.6,1.27),dark,Vector3(0,0,0.55)).add_to_group("ship_cockpit_fault")
	if "quarters" not in Game.state.owned:
		var service := BoxMesh.new()
		service.size = Vector3(1,0.55,0.08)
		add_mesh(service,Vector3(0,0.4,1.27),dark).add_to_group("ship_cabin_fault")
		box(Vector3(0,0.3,1.33),Vector3(0.07,0.8,0.04),brass)
	for side in [-1,1]:
		for x in [-3.7,-2.8,-1.7]:
			var frame := BoxMesh.new()
			frame.size = Vector3(0.09,0.76,0.1)
			add_mesh(frame,Vector3(x,0.52,side*1.28),bright,Vector3(0,0,-0.25))
		prism(PackedVector2Array([Vector2(-4.8,-0.12),Vector2(-3.1,-0.55),Vector2(-1.1,-0.62),Vector2(-1.1,-0.87),Vector2(-3.4,-0.73)]),0.16,Vector3(0,0,side*1.15),paint)
		for x in [3.8,4.3,4.8]:
			box(Vector3(x,0.5,side*1.0),Vector3(0.4,0.14,0.8),bright)
			box(Vector3(x,-0.65,side*1.0),Vector3(0.4,0.12,0.8),steel)
		for z in [-0.25,0.25]:
			cylinder(Vector3(3.6,0.15,side*1.0+z),0.065,1.5,brass)
		box(Vector3(1,-0.65,side*1.3),Vector3(2,0.3,0.6),dark)
		cylinder(Vector3(0.5,-0.82,side*1.6),0.22,1.5,steel)
	for side in [-1,1]:
		for x in range(-1,4):
			box(Vector3(x,0.65,side*1.24),Vector3(0.84,0.42,0.12),bright)
			box(Vector3(x,-0.45,side*1.25),Vector3(0.82,0.28,0.12),steel)
			for vent in range(4):
				box(Vector3(x-0.25+vent*0.16,-0.44,side*1.32),Vector3(0.07,0.17,0.03),dark)
		cylinder(Vector3(0.7,-0.87,side*1.05),0.11,6.2,brass)
		for x in [-2,0,2,3]:
			cylinder(Vector3(x,-0.87,side*1.05),0.17,0.15,steel)
		if "cockpit" not in Game.state.owned:
			for segment in range(3):
				var shard := BoxMesh.new()
				shard.size = Vector3(0.27,0.022,0.035)
				add_mesh(shard,Vector3(-3.15+segment*0.18,0.6-segment*0.13,side*1.28),bright,Vector3(0,0,0.8 if segment%2 == 0 else -0.8))
	for x in range(-2,4):
		box(Vector3(x,1.15,0),Vector3(0.65,0.15,1.1),bright)
		for z in [-0.3,0.3]:
			box(Vector3(x,1.24,z),Vector3(0.35,0.05,0.08),dark)
	box(Vector3(1.4,1.8,0),Vector3(0.12,1.2,0.12),brass)
	box(Vector3(1.4,2.35,0),Vector3(0.5,0.12,0.35),cyan)
	for id in Game.state.expansions:
		var position := Vector3(0,-2.0,0)
		if id == "fabrication": position.x = 3
		if id == "habitat": position.y = -3.7
		box(position,Vector3(2.6,1.15,2.1),steel)
		var shaft := BoxMesh.new()
		shaft.size = Vector3(0.75,1.25,0.85) if id != "fabrication" else Vector3(1.0,0.7,0.85)
		var join_position := Vector3(0,-1.25,0)
		if id == "habitat": join_position.y = -2.85
		if id == "fabrication": join_position = Vector3(1.5,-2,0)
		add_mesh(shaft,join_position,dark).add_to_group("ship_deck_connector")
		for side in [-1,1]:
			box(join_position+Vector3(0,0,side*0.46),Vector3(0.9,0.18,0.12),brass)
			box(position+Vector3(0,-0.55,side*0.95),Vector3(2.8,0.15,0.18),bright)

		box(position+Vector3(0,0.8,0),Vector3(0.4,0.8,0.4),dark)
		for side in [-1,1]:
			box(position+Vector3(0,0.15,side*1.07),Vector3(1.9,0.45,0.04),material("6dbb91" if id == "habitat" else "5fbcc7",true))
	var sphere := SphereMesh.new()
	sphere.radius = 6
	sphere.height = 12
	var scan_mat := material("4e9aa3")
	scan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scan_mat.albedo_color.a = 0.05
	scan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scanner = add_mesh(sphere,Vector3.ZERO,scan_mat)
	scanner.visible = "deep_scanner" in Game.state.research

func reset_view() -> void:
	yaw = -0.85
	pitch = 0.35
	distance = 17
	target = Vector3(0,-0.5 if not Game.state.expansions.is_empty() else 0,0)
	update_camera()

func update_camera() -> void:
	queue_redraw()
	if not is_instance_valid(camera): return
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target,Vector3.UP)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			previous_mouse = event.position
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance*(0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1),8,35)
		update_camera()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position-previous_mouse
		previous_mouse = event.position
		if event.shift_pressed:
			target += (-camera.basis.x*delta.x+camera.basis.y*delta.y)*distance*0.0015
		else:
			yaw -= delta.x*0.008
			pitch = clampf(pitch+delta.y*0.006,-1.1,1.1)
		update_camera()
		accept_event()

func set_pixel_style(value: bool) -> void:
	pixel_style = value
	viewport_container.visible = not value
	queue_redraw()

func frame_index() -> int:
	var order := [0,1,2,3,7,6,5,4]
	return order[posmod(roundi((yaw+0.85)/TAU*8),8)]

func _process(_delta: float) -> void:
	if is_instance_valid(model):
		var drift := drift_offset(Game.state.cruise_seconds)
		model.position = Vector3(0,drift.y*0.035,drift.x*0.025)
	queue_redraw()

func _draw() -> void:
	if backdrop == null: return
	var area := background_camera()
	var factor := size.y/area.size.y
	draw_set_transform(size/2-area.get_center()*factor,0,Vector2.ONE*factor)
	backdrop.draw_world(self,Game.state.cruise_seconds,area)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if not pixel_style: return
	var r: Array = pixel_frames[frame_index()]
	var source := Rect2(r[0],r[1],r[2],r[3])
	var scale := minf(size.x*0.9/source.size.x,size.y*0.9/source.size.y)*17.0/distance
	var extent := source.size*scale
	var center := size/2+Vector2(-target.x,target.y)*30+drift_offset(Game.state.cruise_seconds)
	diorama_art.draw(self,frame_index(),source,Rect2(center-extent/2,extent),Game.state.owned,Game.state.hull_integrity)
	for id in Game.state.expansions:
		var offset := Vector2(20,extent.y*0.3)
		if id == "fabrication": offset.x += 60
		if id == "habitat": offset.y += 40
		var item: Dictionary = Game.catalog_item(Game.expansion_catalog,id)
		var point := center+offset
		var width := 72*scale
		var height := 48*scale
		var vertices := PackedVector2Array([point,point+Vector2(width,-height*0.15),point+Vector2(width,height*0.85),point+Vector2(0,height)])
		var source_rect := Rect2(item.column*512,300,512,400)
		var uv := PackedVector2Array([source_rect.position,Vector2(source_rect.end.x,source_rect.position.y),source_rect.end,Vector2(source_rect.position.x,source_rect.end.y)])
		for i in range(uv.size()): uv[i] /= Vector2(1536,1024)
		draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,MODULE_ATLAS)

func background_camera() -> Rect2:
	var height := 240.0
	var extent := Vector2(height*maxf(size.x,1)/maxf(size.y,1),height)
	var center := Vector2(140,75)
	return Rect2(center-extent/2,extent)

func drift_offset(time: float) -> Vector2:
	return Vector2(sin(time*0.2)*2.5,sin(time*0.17)*1.5)

func damage_description() -> String:
	var state: Dictionary = diorama_art.damage_state(Game.state.owned,Game.state.hull_integrity)
	if state.broken.is_empty():
		return "Primary systems restored." + (" Minor hull scuffs remain." if state.hull_wear else "")
	return "Visible faults: " + ", ".join(state.broken) + ". Restore them in Shop / Room repairs."

