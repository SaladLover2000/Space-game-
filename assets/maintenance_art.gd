extends RefCounted
const ATLAS = preload("res://assets/art/maintenance-hardware-v1.png")
const SOURCES = {"frame":Rect2(80,10,425,485),"door":Rect2(575,10,390,485),"winch":Rect2(20,523,600,260),"chain":Rect2(745,515,55,285),"spreader":Rect2(922,580,600,380)}
func draw(canvas: CanvasItem, id: String, rect: Rect2) -> void:
	canvas.draw_texture_rect_region(ATLAS,rect,SOURCES[id])
func hoist_lift(progress: float) -> float:
	return clampf(progress,0,1)*8.0

