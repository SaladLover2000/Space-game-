extends RefCounted
const RESTORED = preload("res://assets/art/ship-pixel-angles-v2.png")
const DAMAGED = preload("res://assets/art/ship-pixel-angles-damaged-v1.png")
# Per-angle source regions for the visible command cabin, central systems and aft machinery.
const ZONES = [
	{"cockpit":Rect2(0.02,0.35,0.36,0.42),"quarters":Rect2(0.36,0.25,0.28,0.40),"engine":Rect2(0.65,0.23,0.35,0.60)},
	{"cockpit":Rect2(0.02,0.55,0.38,0.40),"quarters":Rect2(0.35,0.30,0.30,0.40),"engine":Rect2(0.65,0.13,0.35,0.55)},
	{"cockpit":Rect2(0.25,0.65,0.50,0.35),"quarters":Rect2(0.25,0.35,0.50,0.28),"engine":Rect2(0.15,0.00,0.70,0.33)},
	{"cockpit":Rect2(0.60,0.55,0.40,0.40),"quarters":Rect2(0.40,0.25,0.25,0.35),"engine":Rect2(0.00,0.10,0.40,0.60)},
	{"cockpit":Rect2(0.55,0.00,0.45,0.28),"quarters":Rect2(0.38,0.25,0.35,0.30),"engine":Rect2(0.00,0.38,0.55,0.62)},
	{"cockpit":Rect2(0.60,0.00,0.40,0.28),"quarters":Rect2(0.38,0.25,0.35,0.30),"engine":Rect2(0.00,0.40,0.55,0.60)},
	{"cockpit":Rect2(0.25,0.00,0.50,0.22),"quarters":Rect2(0.15,0.23,0.70,0.30),"engine":Rect2(0.00,0.55,1.00,0.45)},
	{"cockpit":Rect2(0.00,0.00,0.40,0.30),"quarters":Rect2(0.28,0.25,0.35,0.30),"engine":Rect2(0.50,0.40,0.50,0.60)}
]

func damage_state(owned: Array, hull_integrity: float = 100) -> Dictionary:
	var broken: Array[String] = []
	for id in ["cockpit","quarters","engine"]:
		if id not in owned: broken.append(id)
	return {"broken":broken,"base":DAMAGED if not broken.is_empty() else RESTORED,"hull_wear":hull_integrity<100}

func repair_regions(frame: int, owned: Array) -> Array:
	var result: Array = []
	for id in ["cockpit","quarters","engine"]:
		if id in owned: result.append({"id":id,"region":ZONES[frame][id]})
	return result

func draw(canvas: CanvasItem, frame: int, source: Rect2, destination: Rect2, owned: Array, hull_integrity: float) -> void:
	var state := damage_state(owned,hull_integrity)
	canvas.draw_texture_rect_region(state.base,destination,source)
	if not state.broken.is_empty():
		for part in repair_regions(frame,owned):
			var area: Rect2 = part.region
			var src := Rect2(source.position+source.size*area.position,source.size*area.size)
			var dst := Rect2(destination.position+destination.size*area.position,destination.size*area.size)
			canvas.draw_texture_rect_region(RESTORED,dst,src)
	if state.hull_wear:
		var point := destination.position+destination.size*Vector2(0.47,0.48)
		canvas.draw_line(point,point+Vector2(8,3),Color("68534a"),1)
		canvas.draw_line(point+Vector2(3,2),point+Vector2(10,4),Color("b49c80"),0.5)
