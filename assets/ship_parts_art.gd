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
		canvas.draw_texture_rect_region(finish.painted(EXTERIOR,paint),rect,Rect2(815,362,35,324))
		canvas.draw_rect(rect,Color("333c41"),false,0.6)
		canvas.draw_line(rect.position+Vector2(1,0),rect.position+Vector2(1,rect.size.y),Color("c3bba3"),0.7)
		for fraction in [0.10,0.35,0.65,0.90]:
			canvas.draw_rect(Rect2(rect.position+Vector2(2,rect.size.y*fraction),Vector2(rect.size.x-4,1.8)),Color("b79b65"))
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
		for y in [49,83]: result.append({"id":engine,"rect":Rect2(252,y,43,30)})
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
		for x in [94,163,222]: result.append({"id":hull,"rect":Rect2(x,42,9,73)})
	return result
func draw_equipped(canvas: CanvasItem, equipment: Dictionary) -> void:
	for part in installed_parts(equipment): draw_component(canvas,part.id,part.rect,equipment.get("paint","paint_stock"),part.get("flip_y",false))
