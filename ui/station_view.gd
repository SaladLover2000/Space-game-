extends Control
var panel_texture: Texture2D
var planet_index: int = -1
var world: SubViewport
var station: Node3D
var clock: float = 0
var backdrop := preload("res://assets/space_backdrop.gd").new()
func _ready() -> void:
	var painter := preload("res://ui/ship_3d.gd").new()
	panel_texture = painter.panel_texture(Color.WHITE)
	painter.free()
	custom_minimum_size = Vector2(620,400)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	add_child(container)
	world = SubViewport.new()
	world.size = Vector2i(620,400)
	world.transparent_bg = true
	world.own_world_3d = true
	container.add_child(world)
	station = Node3D.new()
	station.add_to_group("volumetric_station")
	world.add_child(station)
	var camera := Camera3D.new()
	camera.position = Vector3(6,4,7)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-25,0)
	sun.light_energy = 1.5
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CANVAS
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b8c4d8")
	env.environment.ambient_light_energy = 0.65
	world.add_child(env)
	if planet_index >= 0:
		build_planet()
		return
	for position in [Vector3(-1.6,0,0),Vector3.ZERO,Vector3(1.6,0,0)]:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.65
		mesh.bottom_radius = 0.65
		mesh.height = 1.55
		mesh.radial_segments = 12
		part(mesh,position,"c4c6b8",Vector3(0,0,PI/2))
		for dx in [-0.6,0.6]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.60
			ring.outer_radius = 0.71
			part(ring,position+Vector3(dx,0,0),"b89860",Vector3(0,0,PI/2))
	for sign_value in [-1,1]:
		for x in [-1.2,1.2]:
			for tile in range(4):
				var panel := BoxMesh.new()
				panel.size = Vector3(0.85,0.05,0.5)
				part(panel,Vector3(x,0.35,sign_value*(1.0+tile*0.53)),"284164")
	var tower := CylinderMesh.new()
	tower.top_radius = 0.45
	tower.bottom_radius = 0.45
	tower.height = 2.8
	part(tower,Vector3.ZERO,"c4c6b8")
func part(mesh: Mesh, position: Vector3, color: String, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.9
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if color == "c4c6b8": material.albedo_texture = panel_texture
	instance.material_override = material
	station.add_child(instance)
func _process(delta: float) -> void:
	clock += delta
	station.rotation.y = sin(clock*0.07)*0.15
	queue_redraw()
func _draw() -> void:
	var factor := size.y/240
	draw_set_transform(Vector2(0,50*factor),0,Vector2.ONE*factor)
	backdrop.draw_world(self,Game.state.cruise_seconds,Rect2(0,-50,size.x/factor,240))

func build_planet() -> void:
	station.remove_from_group("volumetric_station")
	station.add_to_group("volumetric_planet")
	var mesh := SphereMesh.new()
	mesh.radius = 2.5
	mesh.height = 5
	mesh.radial_segments = 32
	mesh.rings = 20
	var image := Image.create(192,96,false,Image.FORMAT_RGBA8)
	var palette: Array = backdrop.PALETTES[planet_index%3]
	for y in range(96):
		for x in range(192):
			var value := sin(y*0.22+sin(x*TAU/192)*1.7)*1.1+sin(x*TAU*5/192+y*0.18)*0.6
			image.set_pixel(x,y,Color(palette[clampi(int(value+2),0,4)]))
	var sphere := MeshInstance3D.new()
	sphere.mesh = mesh
	var surface := StandardMaterial3D.new()
	surface.albedo_texture = ImageTexture.create_from_image(image)
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	surface.roughness = 1
	sphere.material_override = surface
	station.add_child(sphere)
