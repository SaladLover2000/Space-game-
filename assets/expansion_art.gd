extends RefCounted
const ATLAS = preload("res://assets/art/expansion-modules-v1.png")

func draw(canvas: CanvasItem, item: Dictionary, preview: bool = false) -> void:
	var b: Array = item.bounds
	var bounds := Rect2(b[0],b[1],b[2],b[3])
	var tint := Color(0.72,0.85,1,0.55) if preview else Color.WHITE
	var start := Vector2(130,248) if item.id == "habitat" else Vector2(172,216) if item.id == "fabrication" else Vector2(130,108)
	var finish := Vector2(178,216) if item.id == "fabrication" else Vector2(bounds.get_center().x,bounds.position.y+7)
	canvas.draw_line(start,finish,Color("172c3e"),10)
	canvas.draw_line(start+Vector2(3,0),finish+Vector2(3,0),Color("7b939c"),1)
	canvas.draw_line(start-Vector2(3,0),finish-Vector2(3,0),Color("7b939c"),1)
	if item.id != "fabrication":
		for y in range(int(start.y),int(finish.y),7):
			canvas.draw_line(Vector2(start.x-2,y),Vector2(start.x+2,y),Color("7b939c"),0.8)
	canvas.draw_texture_rect_region(ATLAS,bounds,Rect2(item.column*512,300,512,400),tint)
	if preview:
		canvas.draw_rect(bounds,Color("7de1d6"),false,1)
