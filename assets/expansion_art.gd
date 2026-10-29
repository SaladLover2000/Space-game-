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

func connection(item: Dictionary) -> Dictionary:
	var start := Vector2(130,110)
	var finish := Vector2(130,191)
	if item.id == "habitat":
		start = Vector2(130,244)
		finish = Vector2(130,267)
	elif item.id == "fabrication":
		start = Vector2(166,216)
		finish = Vector2(185,216)
	return {"start":start,"finish":finish,"width":18.0}

func draw_connection(canvas: CanvasItem, item: Dictionary) -> void:
	var link := connection(item)
	var a: Vector2 = link.start
	var b: Vector2 = link.finish
	canvas.draw_line(a,b,Color("101923"),20)
	canvas.draw_line(a,b,Color("445765"),16)
	canvas.draw_line(a,b,Color("1c2a35"),10)
	if item.id == "fabrication":
		for y in [-8,8]: canvas.draw_line(a+Vector2(0,y),b+Vector2(0,y),Color("bdc8c9"),2)
	else:
		for x in [-8,8]: canvas.draw_line(a+Vector2(x,0),b+Vector2(x,0),Color("bdc8c9"),2)
		for y in range(int(a.y)+4,int(b.y),6):
			canvas.draw_line(Vector2(a.x-4,y),Vector2(a.x+4,y),Color("9ba8a8"),1)
		for end in [a,b]:
			canvas.draw_rect(Rect2(end-Vector2(13,3),Vector2(26,6)),Color("8c9ca2"))
			canvas.draw_rect(Rect2(end-Vector2(10,1),Vector2(20,2)),Color("b58e52"))
		if item.id == "lab":
			for x in [-1,1]:
				canvas.draw_line(Vector2(130+x*30,116),Vector2(130+x*38,191),Color("18232e"),6)
				canvas.draw_line(Vector2(130+x*30,116),Vector2(130+x*38,191),Color("9aa8ac"),2)

