extends RefCounted
## Original generated raster sprites calibrated to the existing gameplay coordinates.
const RESTORED = preload("res://assets/art/ship-cutaway-restored-v1.png")
const DAMAGED = preload("res://assets/art/ship-cutaway-damaged-v1.png")
const EXTERIOR = preload("res://assets/art/ship-exterior-v1.png")
const CORE_EXTERIOR = preload("res://assets/art/ship-core-exterior-v1.png")
const CORE_RESTORED = preload("res://assets/art/ship-core-restored-v1.png")
const CORE_DAMAGED = preload("res://assets/art/ship-core-damaged-v1.png")
const QUARTERS = preload("res://assets/art/companion-quarters-v1.png")
var decals := preload("res://assets/decal_art.gd").new()
var service := preload("res://assets/service_art.gd").new()
var finish := preload("res://assets/material_finish.gd").new()
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

func skin_texture(raw: Texture2D, equipment: Dictionary, exterior: bool) -> Texture2D:
	var selected: Texture2D = raw
	if equipment.get("wings","wings_stock") != "wings_stock":
		selected = CORE_EXTERIOR if exterior else CORE_RESTORED if raw == RESTORED else CORE_DAMAGED
	return finish.exterior_lights(finish.painted(selected,equipment.get("paint","paint_stock"),{},not exterior),equipment.get("lights","lights_stock"),not exterior)

func draw(canvas: CanvasItem, owned: Array, exterior: bool, equipment: Dictionary, time: float, condition: float, calm_lights: bool = true, hull_integrity: float = 100) -> void:
	if exterior:
		draw_skin(canvas,skin_texture(EXTERIOR,equipment,true),equipment)
		decals.draw(canvas,Rect2(106,72,36,18))
		if hull_integrity < 100: draw_scuffs(canvas)
		return
	var status := system_status(owned,time,calm_lights)
	var fully_restored: bool = not status.engine_broken and not status.bridge_broken and not status.quarters_broken
	draw_skin(canvas,skin_texture(RESTORED if fully_restored else DAMAGED,equipment,false),equipment)
	var theme: String = equipment.get("interior", "interior_stock")
	var tint := Color.WHITE
	if theme == "interior_habitat":
		tint = Color(1.0, 0.88, 0.72)
	elif theme == "interior_lab":
		tint = Color(0.72, 0.94, 1.0)
	for id in ROOM_SOURCES:
		var region: Rect2 = ROOM_SOURCES[id]
		if id == "quarters":
			canvas.draw_texture_rect(quarters_texture(owned),source_to_world(region),false,tint)
		else: canvas.draw_texture_rect_region(skin_texture(texture_for_room(id, owned),equipment,false), source_to_world(region), region, tint)
	service.draw_cabin(canvas,"dock",Rect2(99,61,34,43))
	service.draw_cabin(canvas,"bench",Rect2(132,58,24,46))
	if "quarters" not in owned: service.draw(canvas,"spares",Rect2(158,97,15,8))
	draw_decor(canvas,Rect2(99,55,77,49))
	decals.draw(canvas,Rect2(115,110,30,7))
	if hull_integrity < 100: draw_scuffs(canvas)
	if status.engine_broken:
		draw_fault_effects(canvas,time,condition,calm_lights)

func draw_fault_effects(canvas: CanvasItem, time: float, condition: float, calm_lights: bool = true) -> void:
	# Animated light exactly over the bitmap's red fault lamp, not a baked animation.
	var lit: bool = system_status([],time,calm_lights).warning_on
	canvas.draw_rect(Rect2(182.8, 61.5, 2.4, 3.5), Color("ff5d66" if lit else "4e2530"))
	if lit:
		canvas.draw_circle(Vector2(184,63), 3.0, Color(1,0.15,0.20,0.10))
	for i in range(5):
		var age := fposmod(time * 0.65 + i * 0.21, 1.0)
		var alpha := (1.0-age) * (0.30 if condition < 50 else 0.15)
		canvas.draw_circle(Vector2(240 + sin(age*4+i)*2, 83-age*12), 0.7+age*1.8, Color(0.75,0.87,0.92,alpha))

func system_status(owned: Array, time: float, calm_lights: bool = false) -> Dictionary:
	return {"engine_broken": "engine" not in owned, "bridge_broken": "cockpit" not in owned, "quarters_broken": "quarters" not in owned, "warning_on": calm_lights or fposmod(time,1.2)<0.6}

func draw_scuffs(canvas: CanvasItem) -> void:
	for p in [Vector2(125,108),Vector2(177,44)]:
		canvas.draw_line(p,p+Vector2(5,2),Color("5b4c49"),0.8)
		canvas.draw_line(p+Vector2(1,1),p+Vector2(4,2),Color("ad8c70"),0.5)

func skin_regions(equipment: Dictionary) -> Array[Rect2]:
	if equipment.get("engine","engine_stock") == "engine_stock": return [SPRITE_RECT]
	# Mount socket is x252; only those two old engine pods are removed.
	return [Rect2(-33,-39,271,228),Rect2(238,-39,62,74),Rect2(238,129,62,60)]
func draw_skin(canvas: CanvasItem, texture: Texture2D, equipment: Dictionary) -> void:
	for rect in skin_regions(equipment):
		var uv := Rect2((rect.position-SPRITE_RECT.position)/SPRITE_RECT.size*SOURCE_SIZE,rect.size/SPRITE_RECT.size*SOURCE_SIZE)
		canvas.draw_texture_rect_region(texture,rect,uv)

func draw_decor(canvas: CanvasItem, area: Rect2) -> void:
	var decorations: Array = Engine.get_main_loop().root.get_node("Game").state.get("quarters_decor",[])
	var origin := area.position
	var scale := area.size/Vector2(77,49)
	if "terrarium" in decorations:
		canvas.draw_rect(Rect2(origin+Vector2(65,31)*scale,Vector2(7,8)*scale),Color("283d46"))
		canvas.draw_rect(Rect2(origin+Vector2(67,28)*scale,Vector2(2,8)*scale),Color("698b66"))
		canvas.draw_rect(Rect2(origin+Vector2(64,30)*scale,Vector2(7,2)*scale),Color("91ae77"))
	if "tool_rack" in decorations:
		for i in range(4): canvas.draw_line(origin+Vector2(40+i*3,3)*scale,origin+Vector2(40+i*3,8)*scale,Color("b2a78e"),maxf(0.4,scale.x))
	if "relay_project" in decorations:
		canvas.draw_rect(Rect2(origin+Vector2(42,20)*scale,Vector2(9,4)*scale),Color("34584b"))
		for i in range(3): canvas.draw_rect(Rect2(origin+Vector2(43+i*2,21)*scale,Vector2.ONE*scale),Color("d4ad61"))

func quarters_texture(owned: Array) -> Texture2D:
	return finish.worn(QUARTERS,100 if "quarters" in owned else 25)
