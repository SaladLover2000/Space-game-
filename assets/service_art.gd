extends RefCounted
const ATLAS = preload("res://assets/art/space-service-parts-v1.png")
const SOURCES = {"antenna_dish":Rect2(20,35,525,450),"antenna_sensor":Rect2(585,90,410,400),"antenna_radar":Rect2(1110,15,425,480),"dock":Rect2(20,505,440,515),"station":Rect2(470,505,635,515),"spares":Rect2(1100,540,435,475)}
func draw(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	if id == "spares":
		var props := preload("res://assets/pixel_props.gd").new()
		canvas.draw_rect(rect,Color("192a39"))
		canvas.draw_rect(Rect2(rect.position,Vector2(rect.size.x,maxf(0.5,rect.size.y*0.08))),Color("b98b48"))
		for index in range(3): props.draw_part(canvas,index,rect.position+rect.size*Vector2(0.20+index*0.30,0.50),minf(rect.size.x/42,rect.size.y/16))
		return
	canvas.draw_texture_rect_region(ATLAS,rect,SOURCES[id])

const CABIN = preload("res://assets/art/cabin-fixtures-v1.png")
func draw_cabin(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	var region := Rect2(95,20,660,740) if id == "dock" else Rect2(985,105,970,620)
	canvas.draw_texture_rect_region(CABIN,rect,region)
