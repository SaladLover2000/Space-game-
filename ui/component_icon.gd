extends Control
const RobotArt = preload("res://assets/robot_art.gd")
const ShipPartsArt = preload("res://assets/ship_parts_art.gd")
var robot_art := RobotArt.new()
var ship_art := ShipPartsArt.new()
var item_id: String = ""
var slot: String = ""
func _ready() -> void:
	custom_minimum_size = Vector2(112,112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func component_sources() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not robot_art.regions.has(item_id): return result
	for side in robot_art.regions[item_id]: result.append(robot_art.source(item_id,side))
	return result
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101923"))
	draw_rect(Rect2(Vector2.ONE*3,size-Vector2.ONE*6),Color("50616b"),false,1)
	if slot == "robot_paint":
		draw_rect(Rect2(size*0.2,size*0.6),robot_art.finish_color({"robot_paint":item_id}))
		return
	if not slot.begins_with("robot_"):
		ship_art.draw_component(self,item_id,Rect2(Vector2.ONE*8,size-Vector2.ONE*16))
		return
	var sources := component_sources()
	var cell_width := (size.x-16)/maxi(1,sources.size())
	for index in range(sources.size()):
		var source: Rect2 = sources[index]
		var factor := minf((cell_width-4)/source.size.x,(size.y-16)/source.size.y)
		var extent := source.size*factor
		var center := Vector2(8+cell_width*(index+0.5),size.y/2)
		draw_texture_rect_region(robot_art.texture_for(item_id),Rect2(center-extent/2,extent),source,robot_art.finish_color(Game.state.equipped))

