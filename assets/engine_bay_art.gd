extends RefCounted
const ATLAS = preload("res://assets/art/engine-modules-v1.png")
const IDS = ["pump","injector","cooling","nozzle"]
var sources: Dictionary = {}
func source(id: String, row: int) -> Rect2:
	var key := id+str(row)
	if sources.has(key): return sources[key]
	var cell := Vector2i(ATLAS.get_width()/4,ATLAS.get_height()/4)
	var origin := Vector2i(IDS.find(id)*cell.x,row*cell.y)
	var bounds := ATLAS.get_image().get_region(Rect2i(origin,cell)).get_used_rect()
	var result := Rect2(origin+bounds.position,bounds.size)
	sources[key] = result
	return result
func layout(tiers: Dictionary, condition: float, repaired: bool, preview: Dictionary = {}) -> Array:
	var result := []
	for index in range(IDS.size()):
		var id: String = IDS[index]
		var tier: int = preview.get(id,tiers.get(id,0))
		var row := 0 if not repaired or condition < 40 else mini(3,tier+1)
		if preview.has(id): row = mini(3,tier+1)
		var rect := Rect2(0.08+index*0.225,0.23,0.22,0.40)
		if id == "cooling": rect = Rect2(0.54,0.14,0.20,0.35)
		if id == "nozzle": rect = Rect2(0.76,0.22,0.23,0.43)
		result.append({"id":id,"tier":tier,"row":row,"source":source(id,row),"rect":rect,"preview":preview.has(id)})
	return result
func draw(canvas: CanvasItem, size: Vector2, tiers: Dictionary, condition: float, repaired: bool, preview: Dictionary = {}) -> void:
	# Combustion duct and fuel/coolant circuits join the independently replaceable units.
	var tube := Rect2(size*Vector2(0.49,0.43),size*Vector2(0.30,0.14))
	var source_rect := source("injector",0 if not repaired or condition < 40 else 1)
	canvas.draw_texture_rect_region(ATLAS,tube,Rect2(source_rect.position+source_rect.size*Vector2(0.45,0.25),source_rect.size*Vector2(0.38,0.50)))
	for y in [0.28,0.58]:
		var points := PackedVector2Array([size*Vector2(0.18,y),size*Vector2(0.18,y-0.06),size*Vector2(0.69,y-0.06),size*Vector2(0.69,y)])
		canvas.draw_polyline(points,Color("352f28"),maxf(3,size.y*0.014))
		canvas.draw_polyline(points,Color("b58c55"),maxf(1,size.y*0.006))
	for piece in layout(tiers,condition,repaired,preview):
		var area := Rect2(piece.rect.position*size,piece.rect.size*size)
		canvas.draw_texture_rect_region(ATLAS,area,piece.source)
		if piece.tier == 3:
			# Top-tier bypass assembly is physical additional plumbing, not a tint.
			var pipe := area.position+Vector2(area.size.x*0.2,area.size.y*0.86)
			canvas.draw_polyline(PackedVector2Array([pipe,pipe+Vector2(0,10),pipe+Vector2(area.size.x*0.65,10),pipe+Vector2(area.size.x*0.65,-5)]),Color("aa8050"),3)
			for x in [0.0,0.65]: canvas.draw_rect(Rect2(pipe+Vector2(area.size.x*x-3,5),Vector2(6,8)),Color("d1c3a1"))
		if piece.preview: canvas.draw_rect(area.grow(3),Color("d9bd78"),false,1)
