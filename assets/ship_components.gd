extends RefCounted
## Replaceable original component overlays, shared by preview and equipped ships.
var canvas: CanvasItem

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	canvas.draw_rect(Rect2(x, y, w, h), Color(color))

func polygon(points: Array, color: String) -> void:
	var vertices := PackedVector2Array()
	for p in points:
		vertices.append(Vector2(p[0], p[1]))
	canvas.draw_colored_polygon(vertices, Color(color))

func draw(target: CanvasItem, equipment: Dictionary, cutaway: bool, detailed: bool = false) -> void:
	canvas = target
	var paint: String = equipment.get("paint", "paint_stock")
	if paint != "paint_stock":
		var accent := "74bee4" if paint == "paint_cobalt" else "dfb27b"
		var panel := "344f92" if paint == "paint_cobalt" else "9e644f"
		for x in [44, 107, 179]:
			box(x, 46 if x == 44 else 54 if x == 107 else 48, 27, 2, accent)
		box(44, 110, 33, 2, panel)
		box(181, 115, 25, 2, accent)
		if not cutaway and not detailed:
			polygon([[105,62],[148,62],[153,68],[153,81],[105,81]], panel)
			box(110, 68, 12, 9, "183247")
			box(132, 68, 12, 9, "183247")
			box(112, 70, 8, 4, accent)
			box(134, 70, 8, 4, accent)
	var hull: String = equipment.get("hull", "hull_stock")
	if hull == "hull_ribs":
		for x in [94, 162, 223]:
			box(x, 54, 4, 52, "192c43")
			box(x + 1, 55, 2, 49, "b3c0b6")
			for y in range(61, 102, 10):
				box(x, y, 4, 2, "657f8e")
		for x in range(175, 216, 8):
			box(x, 111, 6, 3, "98adb1")
	if hull == "hull_shielded":
		for x in range(43, 82, 9):
			box(x, 44, 7, 4, "d6dacb")
		for x in range(177, 218, 9):
			box(x, 46, 7, 4, "d6dacb")
			box(x, 113, 7, 4, "c6d2c6")
		box(104, 53, 48, 3, "a8dcce")
		if not cutaway and not detailed:
			for y in [61, 96]:
				box(181, y, 28, 4, "d6dacb")
	var wings: String = equipment.get("wings", "wings_stock")
	if wings == "wings_swept":
		polygon([[188,51],[204,8],[215,8],[223,29],[210,47]], "1d354c")
		polygon([[194,45],[207,12],[213,12],[218,28],[207,43]], "8aa5ad")
		polygon([[190,111],[205,142],[218,142],[225,123],[210,111]], "36576d")
		box(206, 136, 10, 2, "b8c6ba")
	if wings == "wings_solar":
		for origin in [Vector2(194,22), Vector2(195,120)]:
			box(origin.x, origin.y, 29, 13, "98b9bc")
			for x in range(3):
				for y in range(2):
					box(origin.x + 1 + x * 9, origin.y + 1 + y * 6, 8, 5, "34568e")
					box(origin.x + 2 + x * 9, origin.y + 2 + y * 6, 6, 1, "6b9fc0")
	var antenna: String = equipment.get("antenna", "antenna_stock")
	if antenna == "antenna_dish":
		box(169, 28, 2, 15, "9eb5b7")
		polygon([[157,24],[160,20],[180,20],[184,25],[178,30],[164,30]], "182e44")
		polygon([[160,24],[162,22],[178,22],[181,25],[176,28],[165,28]], "8ed4d2")
		box(169, 18, 2, 7, "e5cf99")
	if antenna == "antenna_sensor":
		for x in [161, 179]:
			box(x, 24, 2, 20, "9aaeb5")
			box(x - 3, 22, 8, 5, "54476e")
			box(x - 2, 23, 6, 1, "d7a1e2")
	var lights: String = equipment.get("lights", "lights_stock")
	if lights != "lights_stock":
		var color := "7affd5" if lights == "lights_teal" else "c795f5"
		for x in [47, 64, 108, 128, 146, 182, 202, 218]:
			box(x, 109 if x < 90 else 107 if x < 170 else 115, 5, 2, color)
	var engine: String = equipment.get("engine", "engine_stock")
	for y in ([58, 92] if detailed else [62, 89]):
		if engine == "engine_hauler":
			box(270, y - 2, 25, 3, "c3b294")
			box(270, y + 14, 25, 3, "8fa4ad")
			for x in range(272, 294, 5):
				box(x, y - 3, 2, 5, "657f8f")
		if engine == "engine_ion":
			box(276, y - 3, 21, 4, "334a70")
			box(277, y - 2, 18, 1, "79e7e5")
			box(276, y + 14, 21, 3, "445c84")
			box(296, y + 4, 4, 7, "c7fff0")
