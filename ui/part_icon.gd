extends Control
var slot: String = "engine"
var item_id: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(76, 60)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_rect(Rect2(0, 0, 76, 60), Color("102237"))
	var metal := Color("9bb8bf")
	var accent := Color("7ddfcf")
	if "copper" in item_id:
		accent = Color("edb37e")
	if "violet" in item_id or "sensor" in item_id:
		accent = Color("c399ec")
	if "cobalt" in item_id or "solar" in item_id:
		accent = Color("6fa8e0")
	match slot:
		"engine":
			for y in [12, 34]:
				draw_rect(Rect2(16, y, 36, 14), metal)
				draw_rect(Rect2(20, y + 3, 24, 8), Color("314e68"))
				draw_rect(Rect2(52, y + 2, 6, 10), accent)
		"wings":
			draw_colored_polygon(PackedVector2Array([Vector2(13,44),Vector2(33,9),Vector2(46,9),Vector2(62,44)]), metal)
			draw_colored_polygon(PackedVector2Array([Vector2(24,39),Vector2(36,17),Vector2(41,17),Vector2(51,39)]), accent)
		"antenna":
			draw_rect(Rect2(35, 26, 5, 22), metal)
			draw_colored_polygon(PackedVector2Array([Vector2(12,13),Vector2(62,13),Vector2(50,29),Vector2(25,29)]), metal)
			draw_rect(Rect2(24, 16, 27, 4), accent)
		"paint":
			draw_rect(Rect2(18, 13, 38, 34), metal)
			draw_rect(Rect2(21, 16, 32, 23), accent)
			draw_rect(Rect2(32, 8, 10, 6), Color("516e84"))
		"lights":
			for x in range(13, 64, 15):
				draw_rect(Rect2(x, 24, 10, 14), metal)
				draw_rect(Rect2(x + 2, 26, 6, 10), accent)
		"interior":
			draw_rect(Rect2(12, 10, 51, 40), Color("314b63"))
			draw_rect(Rect2(16, 14, 44, 3), accent)
			draw_rect(Rect2(18, 24, 17, 18), metal)
			draw_rect(Rect2(39, 22, 16, 8), accent)
			draw_rect(Rect2(12, 47, 51, 3), metal)
		_:
			draw_rect(Rect2(15, 12, 46, 37), metal)
			draw_rect(Rect2(20, 17, 36, 27), Color("314e68"))
			for y in range(22, 40, 7):
				draw_rect(Rect2(24, y, 28, 2), accent)
