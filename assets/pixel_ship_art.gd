extends RefCounted
## Original generated raster sprites calibrated to the existing gameplay coordinates.
const RESTORED = preload("res://assets/art/ship-cutaway-restored-v1.png")
const DAMAGED = preload("res://assets/art/ship-cutaway-damaged-v1.png")
const EXTERIOR = preload("res://assets/art/ship-exterior-v1.png")
const SPRITE_RECT = Rect2(-33, -39, 333, 228)
const SOURCE_SIZE = Vector2(1536, 1024)
const ROOM_SOURCES = {
	"cockpit": Rect2(0, 420, 590, 220),
	"quarters": Rect2(590, 420, 355, 220),
	"engine": Rect2(945, 420, 390, 220)
}

func source_to_world(source: Rect2) -> Rect2:
	var ratio := SPRITE_RECT.size / SOURCE_SIZE
	return Rect2(SPRITE_RECT.position + source.position * ratio, source.size * ratio)

func texture_for_room(id: String, owned: Array) -> Texture2D:
	return RESTORED if id in owned else DAMAGED

func draw(canvas: CanvasItem, owned: Array, exterior: bool, equipment: Dictionary, time: float, condition: float) -> void:
	if exterior:
		canvas.draw_texture_rect(EXTERIOR, SPRITE_RECT, false)
		return
	var status := system_status(owned, time)
	var fully_restored: bool = not status.engine_broken and not status.bridge_broken and not status.quarters_broken
	canvas.draw_texture_rect(RESTORED if fully_restored else DAMAGED, SPRITE_RECT, false)
	var theme: String = equipment.get("interior", "interior_stock")
	var tint := Color.WHITE
	if theme == "interior_habitat":
		tint = Color(1.0, 0.88, 0.72)
	elif theme == "interior_lab":
		tint = Color(0.72, 0.94, 1.0)
	for id in ROOM_SOURCES:
		var region: Rect2 = ROOM_SOURCES[id]
		canvas.draw_texture_rect_region(texture_for_room(id, owned), source_to_world(region), region, tint)
	if status.engine_broken:
		draw_fault_effects(canvas, time, condition)

func draw_fault_effects(canvas: CanvasItem, time: float, condition: float) -> void:
	# Animated light exactly over the bitmap's red fault lamp, not a baked animation.
	var lit: bool = system_status([], time).warning_on
	canvas.draw_rect(Rect2(182.8, 61.5, 2.4, 3.5), Color("ff5d66" if lit else "4e2530"))
	if lit:
		canvas.draw_circle(Vector2(184,63), 3.0, Color(1,0.15,0.20,0.10))
	for i in range(5):
		var age := fposmod(time * 0.65 + i * 0.21, 1.0)
		var alpha := (1.0-age) * (0.30 if condition < 50 else 0.15)
		canvas.draw_circle(Vector2(240 + sin(age*4+i)*2, 83-age*12), 0.7+age*1.8, Color(0.75,0.87,0.92,alpha))

func system_status(owned: Array, time: float) -> Dictionary:
	return {"engine_broken": "engine" not in owned, "bridge_broken": "cockpit" not in owned, "quarters_broken": "quarters" not in owned, "warning_on": fposmod(time, 1.2) < 0.6}
