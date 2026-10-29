extends RefCounted
const ATLAS = preload("res://assets/art/space-service-parts-v1.png")
const SOURCES = {"antenna_dish":Rect2(20,35,525,450),"antenna_sensor":Rect2(585,90,410,400),"antenna_radar":Rect2(1110,15,425,480),"dock":Rect2(20,505,440,515),"station":Rect2(470,505,635,515),"spares":Rect2(1100,540,435,475)}
func draw(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(ATLAS,rect,SOURCES[id])

const CABIN = preload("res://assets/art/cabin-fixtures-v1.png")
func draw_cabin(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	var region := Rect2(95,20,660,740) if id == "dock" else Rect2(985,105,970,620)
	canvas.draw_texture_rect_region(CABIN,rect,region)
