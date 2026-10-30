extends RefCounted
var finish := preload("res://assets/material_finish.gd").new()
const SERVICE = preload("res://assets/service_art.gd")
var service := SERVICE.new()
const ATLAS = preload("res://assets/art/ship-components-v1.png")
const EXTERIOR = preload("res://assets/art/ship-exterior-v1.png")
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_component_regions.json"))
const CELLS = {"engine_stock":Vector2i(0,0),"engine_hauler":Vector2i(1,0),"engine_ion":Vector2i(2,0),"wings_stock":Vector2i(0,1),"wings_swept":Vector2i(1,1),"wings_solar":Vector2i(2,1),"lights_stock":Vector2i(0,2),"lights_teal":Vector2i(1,2),"lights_violet":Vector2i(2,2)}
func source(id: String) -> Rect2:
	if service.SOURCES.has(id): return service.SOURCES[id]
	var rect: Array = regions.get(id,regions.engine_stock)
	return Rect2(rect[0],rect[1],rect[2],rect[3])

func draw_component(canvas: CanvasItem, id: String, rect: Rect2, paint: String = "paint_stock", flip_y: bool = false) -> void:
	if id in ["hull_ribs","hull_shielded"]:
		for i in range(4):
			var piece := Rect2(rect.position+rect.size*Vector2(0.03+i*0.24,0.15),rect.size*Vector2(0.20,0.70))
			var polygon := PackedVector2Array([piece.position+Vector2(0,piece.size.y*0.12),piece.position+Vector2(piece.size.x*0.80,0),piece.end,Vector2(piece.position.x,piece.end.y)])
			draw_armor_plate(canvas,polygon,id,paint,false)
		return
	if CELLS.has(id) or service.SOURCES.has(id):
		var texture: Texture2D = finish.painted(service.ATLAS if service.SOURCES.has(id) else ATLAS,paint)
		var region := source(id)
		var uv := PackedVector2Array([region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)])
		if flip_y: uv = PackedVector2Array([Vector2(region.position.x,region.end.y),region.end,Vector2(region.end.x,region.position.y),region.position])
		for i in range(4): uv[i] /= Vector2(texture.get_size())
		canvas.draw_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),PackedColorArray([Color.WHITE]),uv,texture)
	else:
		canvas.draw_texture_rect_region(finish.painted(EXTERIOR,id if id.begins_with("paint_") else paint),rect,Rect2(640,445,260,170))

func installed_parts(equipment: Dictionary) -> Array:
	var result := []
	var engine: String = equipment.get("engine","engine_stock")
	if engine != "engine_stock":
		for y in [49,83]: result.append({"id":engine,"rect":Rect2(242,y-3,55,35)})
	var wings: String = equipment.get("wings","wings_stock")
	if wings != "wings_stock":
		result.append({"id":wings,"rect":Rect2(180,-37,100,74)})
		result.append({"id":wings,"rect":Rect2(144,110,112,68),"flip_y":true})
	var lights: String = equipment.get("lights","lights_stock")
	if lights != "lights_stock":
		for point in [Vector2(44,50),Vector2(82,43),Vector2(122,40),Vector2(162,38),Vector2(210,43),Vector2(247,50),Vector2(52,112),Vector2(104,119),Vector2(160,119),Vector2(220,121),Vector2(258,112)]: result.append({"id":lights,"rect":Rect2(point,Vector2(4,4))})
	var antenna: String = equipment.get("antenna","antenna_stock")
	var mounts: Dictionary = Engine.get_main_loop().root.get_node("Game").effective_sensor_mounts()
	if antenna in ["antenna_dish","antenna_sensor","antenna_radar"] and (antenna != Engine.get_main_loop().root.get_node("Game").state.equipped.antenna): mounts["dorsal"] = antenna
	for mount in mounts:
		var rect: Rect2 = {"fore":Rect2(65,22,23,21),"dorsal":Rect2(150,7,35,29),"aft":Rect2(247,17,22,25)}[mount]
		result.append({"id":mounts[mount],"rect":rect,"mount":mount})
	var paint: String = equipment.get("paint","paint_stock")
	# Full hull painting is handled by PixelShipArt, never by a pasted panel.
	var hull: String = equipment.get("hull","hull_stock")
	if hull != "hull_stock":
		for plate in armor_plates(hull): result.append(plate)
	return result
func draw_equipped(canvas: CanvasItem, equipment: Dictionary) -> void:
	for mount in engine_mount_geometry(equipment): canvas.draw_rect(mount.rect,Color(mount.color))
	for part in installed_parts(equipment):
		if part.has("polygon"): draw_armor_plate(canvas,part.polygon,part.id,equipment.get("paint","paint_stock"))
		else: draw_component(canvas,part.id,part.rect,equipment.get("paint","paint_stock"),part.get("flip_y",false))

func armor_plates(id: String) -> Array:
	var shapes := [
		[[42,49],[70,38],[78,38],[80,44],[48,55]],
		[[83,36],[121,34],[123,41],[84,43]],
		[[128,33],[170,33],[174,39],[130,42]],
		[[180,24],[218,24],[226,33],[184,33]],
		[[36,102],[79,105],[83,111],[41,110]],
		[[88,107],[133,107],[138,114],[93,115]],
		[[142,109],[180,108],[184,115],[146,117]],
		[[190,108],[226,105],[231,111],[194,117]]
	]

	var result: Array = []
	for shape in shapes:
		var polygon := PackedVector2Array()
		for point in shape: polygon.append(Vector2(point[0],point[1]))
		var rect := Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: rect = rect.expand(point)
		result.append({"id":id,"polygon":polygon,"rect":rect})
	return result

func draw_armor_plate(canvas: CanvasItem, polygon: PackedVector2Array, id: String, paint: String, world_surface: bool = true) -> void:
	var center := Vector2.ZERO
	for point in polygon: center += point
	center /= polygon.size()
	var inner := PackedVector2Array()
	for point in polygon: inner.append(point.lerp(center,0.07))
	canvas.draw_colored_polygon(polygon,Color("152331"))
	var coat := Color(finish.JOBS.get(paint,"c7c5b5"))
	canvas.draw_colored_polygon(inner,coat if id == "hull_ribs" else coat.lightened(0.12))
	if world_surface:
		var uv := PackedVector2Array()
		for point in inner: uv.append((point-Vector2(-33,-39))/Vector2(333,228))
		canvas.draw_polygon(inner,PackedColorArray([Color(1.08,1.06,1.0)]),uv,finish.painted(EXTERIOR,paint))
	var edge := inner.duplicate()
	edge.append(inner[0])
	canvas.draw_polyline(edge,Color("e3dac2"),0.55)
	for i in range(polygon.size()):
		var bolt := polygon[i].lerp(center,0.23)
		canvas.draw_rect(Rect2(bolt-Vector2.ONE*0.65,Vector2.ONE*1.3),Color("253541"))
		canvas.draw_rect(Rect2(bolt-Vector2.ONE*0.3,Vector2.ONE*0.6),Color("c49b56"))
	var start := inner[0].lerp(center,0.45)
	var end := inner[1].lerp(center,0.45)
	canvas.draw_line(start,end,Color("566877"),0.65)
	# A few fixed surface scratches give metal detail without any animated shimmer.
	for index in range(5):
		var point := center+Vector2(index*2-4,(index%2)*1.3-0.6)
		if Geometry2D.is_point_in_polygon(point,inner): canvas.draw_rect(Rect2(point,Vector2(0.7,0.35)),Color("a39a80"))

func engine_mount_geometry(equipment: Dictionary) -> Array:
	var result: Array = []
	if equipment.get("engine","engine_stock") == "engine_stock": return result
	for y in [49.0,83.0]:
		result.append({"rect":Rect2(229,y+3,34,24),"color":"162433"})
		result.append({"rect":Rect2(231,y+5,32,20),"color":"647078"})
		result.append({"rect":Rect2(231,y+5,32,3),"color":"d3c9b0"})
		result.append({"rect":Rect2(231,y+19,32,6),"color":"2e414e"})
		for x in [235.0,244.0,253.0]:
			result.append({"rect":Rect2(x,y+1,3,28),"color":"283743"})
			result.append({"rect":Rect2(x,y+2,1,26),"color":"bb9454"})
		result.append({"rect":Rect2(228,y-1,7,32),"color":"162433"})
		result.append({"rect":Rect2(229,y,4,30),"color":"d7d0bb"})
		for bolt_y in [y+2,y+26]:
			result.append({"rect":Rect2(230,bolt_y,2,2),"color":"273847"})
			result.append({"rect":Rect2(230,bolt_y,0.8,0.8),"color":"cda45c"})
	return result
