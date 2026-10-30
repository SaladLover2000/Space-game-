extends RefCounted
## Small authored pixel shapes: consistent steel edges, ivory panels and brass fasteners.
const DARK = Color("162433")
const EDGE = Color("586873")
const LIGHT = Color("d7d0b8")
const BRASS = Color("b98b48")

func draw_wrench(canvas: CanvasItem, point: Vector2, angle: float = 0) -> void:
	var outline := PackedVector2Array([Vector2(-0.7,2),Vector2(0.7,2),Vector2(0.7,-3.8),Vector2(2.1,-5),Vector2(2.1,-7),Vector2(1.1,-7),Vector2(0.8,-5.6),Vector2(-0.8,-5.6),Vector2(-1.1,-7),Vector2(-2.1,-7),Vector2(-2.1,-5),Vector2(-0.7,-3.8)])
	for i in range(outline.size()): outline[i] = point+outline[i].rotated(angle)
	canvas.draw_colored_polygon(outline,DARK)
	var handle := PackedVector2Array([Vector2(-0.35,1.5),Vector2(0.35,1.5),Vector2(0.35,-4.7),Vector2(-0.35,-4.7)])
	for i in range(handle.size()): handle[i] = point+handle[i].rotated(angle)
	canvas.draw_colored_polygon(handle,Color("a7b4b8"))
	for side in [-1,1]:
		var jaw := PackedVector2Array([Vector2(side*0.7,-4.5),Vector2(side*1.8,-5.3),Vector2(side*1.7,-6.8),Vector2(side*1.15,-6.7),Vector2(side*0.9,-5.4)])
		for i in range(jaw.size()): jaw[i] = point+jaw[i].rotated(angle)
		canvas.draw_colored_polygon(jaw,LIGHT)

func rack_geometry(rect: Rect2) -> Array:
	var items: Array = []
	for y in [0.08,0.54,0.92]:
		items.append({"rect":Rect2(rect.position+rect.size*Vector2(0,y),rect.size*Vector2(1,0.07)),"color":"162433"})
		items.append({"rect":Rect2(rect.position+rect.size*Vector2(0,y),rect.size*Vector2(1,0.02)),"color":"b98b48"})
	for x in [0.02,0.93]:
		items.append({"rect":Rect2(rect.position+rect.size*Vector2(x,0),rect.size*Vector2(0.05,1)),"color":"586873"})
	return items

func draw_rack(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect,Color("101c29"))
	for piece in rack_geometry(rect): canvas.draw_rect(piece.rect,Color(piece.color))
	for row in range(2):
		for col in range(3):
			var cell := Rect2(rect.position+rect.size*Vector2(0.10+col*0.29,0.19+row*0.43),rect.size*Vector2(0.23,0.28))
			canvas.draw_rect(cell,Color("273c50"))
			canvas.draw_rect(Rect2(cell.position,Vector2(cell.size.x,cell.size.y*0.11)),LIGHT)
			draw_part(canvas,(row*3+col)%3,cell.get_center(),minf(cell.size.x,cell.size.y)/12)

func draw_part(canvas: CanvasItem, kind: int, point: Vector2, scale: float = 1.0) -> void:
	# Polygonal machined gears and couplings, never a pasted photographic thumbnail.
	if kind%3 == 0:
		var gear := PackedVector2Array()
		for i in range(32):
			var radius := 5.0 if i%4 in [0,3] else 6.0
			gear.append(point+Vector2.from_angle(i*TAU/32)*radius*scale)
		canvas.draw_colored_polygon(gear,DARK)
		for i in range(8):
			var pos := point+Vector2.from_angle(i*TAU/8)*3.6*scale
			canvas.draw_rect(Rect2(pos-Vector2.ONE*scale,Vector2.ONE*2*scale),LIGHT)
		canvas.draw_rect(Rect2(point-Vector2.ONE*1.8*scale,Vector2.ONE*3.6*scale),BRASS)
		canvas.draw_rect(Rect2(point-Vector2.ONE*0.8*scale,Vector2.ONE*1.6*scale),DARK)
	elif kind%3 == 1:
		canvas.draw_rect(Rect2(point+Vector2(-5,-3)*scale,Vector2(10,6)*scale),DARK)
		canvas.draw_rect(Rect2(point+Vector2(-4,-2)*scale,Vector2(8,4)*scale),LIGHT)
		for x in [-3,3]: canvas.draw_rect(Rect2(point+Vector2(x,-3.5)*scale,Vector2(1.5,7)*scale),BRASS)
		canvas.draw_rect(Rect2(point+Vector2(-1,-2)*scale,Vector2(2,4)*scale),EDGE)
	else:
		canvas.draw_rect(Rect2(point+Vector2(-5,-3)*scale,Vector2(10,6)*scale),DARK)
		canvas.draw_rect(Rect2(point+Vector2(-4,-2)*scale,Vector2(8,4)*scale),Color("e0d7ba"))
		for i in range(3): canvas.draw_rect(Rect2(point+Vector2(-3+i*2.4,-1)*scale,Vector2(1.2,2)*scale),BRASS)

func draw_support(canvas: CanvasItem, rect: Rect2, ceiling: float, floor_y: float) -> void:
	for x in [rect.position.x+rect.size.x*0.15,rect.end.x-rect.size.x*0.15]:
		canvas.draw_rect(Rect2(x-3,rect.end.y,6,maxf(0,floor_y-rect.end.y)),DARK)
		canvas.draw_rect(Rect2(x-1,rect.end.y,2,maxf(0,floor_y-rect.end.y)),EDGE)
		canvas.draw_rect(Rect2(x-9,floor_y-3,18,6),DARK)
		canvas.draw_rect(Rect2(x-7,floor_y-3,14,2),BRASS)
		for y in range(int(ceiling),int(rect.position.y),6):
			canvas.draw_rect(Rect2(x-2,y,4,4),EDGE,false,1)
	canvas.draw_rect(Rect2(rect.position.x-4,rect.end.y,rect.size.x+8,5),DARK)
	canvas.draw_rect(Rect2(rect.position.x-4,rect.end.y,rect.size.x+8,2),BRASS)
