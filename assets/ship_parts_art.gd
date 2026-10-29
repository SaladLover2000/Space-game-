extends RefCounted
var finish := preload("res://assets/material_finish.gd").new()
const ATLAS = preload("res://assets/art/ship-components-v1.png")
const EXTERIOR = preload("res://assets/art/ship-exterior-v1.png")
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ship_component_regions.json"))
const CELLS = {"engine_stock":Vector2i(0,0),"engine_hauler":Vector2i(1,0),"engine_ion":Vector2i(2,0),"wings_stock":Vector2i(0,1),"wings_swept":Vector2i(1,1),"wings_solar":Vector2i(2,1),"lights_stock":Vector2i(0,2),"lights_teal":Vector2i(1,2),"lights_violet":Vector2i(2,2)}
func source(id: String) -> Rect2:
	var rect: Array = regions.get(id,regions.engine_stock)
	return Rect2(rect[0],rect[1],rect[2],rect[3])

func draw_component(canvas: CanvasItem, id: String, rect: Rect2, paint: String = "paint_stock", flip_y: bool = false) -> void:
	if CELLS.has(id):
		var texture: Texture2D = finish.painted(ATLAS,paint)
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
		for point in [Vector2(82,47),Vector2(152,44),Vector2(219,44)]: result.append({"id":lights,"rect":Rect2(point,Vector2(5,5))})
	var paint: String = equipment.get("paint","paint_stock")
	# Full hull painting is handled by PixelShipArt, never by a pasted panel.
	var hull: String = equipment.get("hull","hull_stock")
	if hull != "hull_stock":
		for x in [94,163,222]: result.append({"id":hull,"rect":Rect2(x,44,5,68)})
	return result
func draw_equipped(canvas: CanvasItem, equipment: Dictionary) -> void:
	for part in installed_parts(equipment): draw_component(canvas,part.id,part.rect,equipment.get("paint","paint_stock"),part.get("flip_y",false))

