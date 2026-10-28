extends RefCounted
const ATLAS = preload("res://assets/art/ship-components-v1.png")
const EXTERIOR = preload("res://assets/art/ship-exterior-v1.png")
const CELLS = {"engine_stock":Vector2i(0,0),"engine_hauler":Vector2i(1,0),"engine_ion":Vector2i(2,0),"wings_stock":Vector2i(0,1),"wings_swept":Vector2i(1,1),"wings_solar":Vector2i(2,1),"lights_stock":Vector2i(0,2),"lights_teal":Vector2i(1,2),"lights_violet":Vector2i(2,2)}
func source(id: String) -> Rect2:
	var cell: Vector2i = CELLS.get(id,Vector2i.ZERO)
	var extent := Vector2(ATLAS.get_size())/3
	return Rect2(Vector2(cell)*extent,extent)
func draw_component(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	if CELLS.has(id): canvas.draw_texture_rect_region(ATLAS,rect,source(id))
	else:
		var tint := Color("87b3ed") if id == "paint_cobalt" else Color("e7b88c") if id == "paint_copper" else Color.WHITE
		canvas.draw_texture_rect_region(EXTERIOR,rect,Rect2(640,445,260,170),tint)
func installed_parts(equipment: Dictionary) -> Array:
	var result := []
	var engine: String = equipment.get("engine","engine_stock")
	if engine != "engine_stock":
		for y in [49,83]: result.append({"id":engine,"rect":Rect2(252,y,43,30)})
	var wings: String = equipment.get("wings","wings_stock")
	if wings != "wings_stock":
		result.append({"id":wings,"rect":Rect2(202,-30,88,60)})
		result.append({"id":wings,"rect":Rect2(180,113,88,60)})
	var lights: String = equipment.get("lights","lights_stock")
	if lights != "lights_stock":
		for point in [Vector2(82,47),Vector2(152,44),Vector2(219,44)]: result.append({"id":lights,"rect":Rect2(point,Vector2(5,5))})
	var paint: String = equipment.get("paint","paint_stock")
	if paint != "paint_stock": result.append({"id":paint,"rect":Rect2(108,58,34,22)})
	var hull: String = equipment.get("hull","hull_stock")
	if hull != "hull_stock":
		for x in [94,163,222]: result.append({"id":hull,"rect":Rect2(x,44,5,68)})
	return result
func draw_equipped(canvas: CanvasItem, equipment: Dictionary) -> void:
	for part in installed_parts(equipment): draw_component(canvas,part.id,part.rect)

