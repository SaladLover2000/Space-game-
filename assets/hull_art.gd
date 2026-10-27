extends RefCounted
## Original layered silhouette shared by exterior and cutaway views.
var canvas: CanvasItem

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	canvas.draw_rect(Rect2(x, y, w, h), Color(color))

func plate(points: Array, fill: String, trim: String = "aebec0") -> void:
	var polygon := PackedVector2Array()
	for p in points:
		polygon.append(Vector2(p[0], p[1]))
	canvas.draw_colored_polygon(polygon, Color(fill))
	polygon.append(polygon[0])
	canvas.draw_polyline(polygon, Color(trim), 1)

func draw(target: CanvasItem, owned: Array, cutaway: bool) -> void:
	canvas = target
	# Swept stabilizers behind the pressure hull, with inset armor and cooling slots.
	plate([[188,55],[209,19],[222,19],[239,60]], "26394e", "c17d69")
	plate([[196,51],[212,23],[220,23],[230,51]], "85949c")
	plate([[205,46],[215,27],[218,27],[225,46]], "4a6375", "5d7b89")
	for y in range(30, 48, 4):
		box(213, y, 8 + (y - 30) / 3.0, 1, "b3bec0")
	plate([[190,100],[210,133],[224,133],[240,94]], "293b4f", "c17d69")
	plate([[199,105],[213,128],[221,128],[230,105]], "738b97")
	plate([[204,108],[215,124],[219,124],[225,108]], "405c71", "5c7b8a")
	# Short forward strakes make the bow read as a distinct command section.
	plate([[31,59],[43,34],[65,34],[85,54]], "6c8796", "c17d69")
	plate([[38,53],[46,39],[62,39],[75,50]], "b0bdbd")
	plate([[32,99],[45,120],[64,120],[83,105]], "587284", "c17d69")
	box(47, 115, 14, 2, "9fb8bb")
	# Chamfered prow, layered belly, broad cargo spine, tapered aft mounting.
	plate([[9,80],[25,57],[43,48],[218,48],[238,59],[254,76],[254,94],[237,109],[38,109],[21,98]], "1c2c42", "a3b9bf")
	plate([[13,80],[28,60],[44,52],[217,52],[235,62],[249,78],[249,92],[234,105],[40,105],[25,95]], "708b9b", "bd826b")
	plate([[17,81],[31,63],[45,56],[216,56],[232,65],[245,79],[245,91],[231,101],[41,101],[28,92]], "39576f", "afc0c0")
	plate([[22,88],[43,97],[232,97],[241,90],[231,104],[40,104]], "263b53", "59798c")
	box(43, 50, 169, 2, "c7d0c6")
	box(43, 53, 165, 1, "4e697c")
	box(42, 106, 188, 2, "c17d69")
	box(44, 104, 181, 1, "91b0b6")
	for x in range(46, 229, 13):
		box(x, 50, 1, 1, "f0e4c7")
		box(x, 106, 1, 1, "f0d6b2")
	# Low dorsal module and a short communications mast.
	plate([[98,48],[104,41],[133,41],[140,48]], "748c99", "bd826b")
	box(106, 42, 24, 2, "c5cebf")
	box(146, 43, 2, 6, "7396a4")
	box(145, 41, 4, 2, "e6ca84")
	if not cutaway:
		draw_armor(owned)

func draw_armor(owned: Array) -> void:
	# Separate cockpit canopy; sloped glass faces the direction of travel.
	plate([[20,79],[34,62],[67,61],[76,70],[76,88],[33,88]], "11243a", "93b4bd")
	plate([[25,78],[37,65],[65,65],[71,71],[71,83],[33,83]], "25657c", "56b4c3")
	plate([[28,76],[38,66],[44,66],[34,77]], "93e4df", "93e4df")
	box(47, 66, 2, 16, "82aab7")
	box(69, 72, 2, 10, "5fd8cf")
	box(34, 87, 40, 2, "1b3048")
	# Independent beveled hull panels, inspection hatches and recessed portholes.
	for x in range(82, 218, 28):
		plate([[x,59],[x + 20,59],[x + 24,63],[x + 24,92],[x + 3,92],[x,88]], "648392", "9eafb5")
		box(x + 2, 61, 18, 2, "b0bcb8")
		box(x + 22, 65, 1, 23, "36536a")
		box(x + 3, 87, 16, 1, "3b566a")
		box(x + 4, 67, 12, 9, "182c43")
		box(x + 6, 69, 8, 5, "7be1d4" if "cockpit" in owned else "568eaa")
		box(x + 4, 80, 5, 3, "879fa7")
		box(x + 5, 81, 1, 1, "ebce89")
	box(88, 95, 113, 2, "6cbbb8")
	box(91, 96, 109, 1, "243d54")
	# Cooling vanes and aft service block break up the rectangular midsection.
	plate([[219,61],[230,66],[238,77],[238,92],[221,98]], "839ba7", "b3c2c1")
	for y in range(70, 94, 4):
		box(222, y, 9, 2, "2b435b")
		box(223, y, 8, 1, "5b8294")
	if "engine" not in owned:
		for p in [Vector2(89,91), Vector2(147,86), Vector2(203,62)]:
			box(p.x, p.y, 4, 1, "a97961")
			box(p.x + 2, p.y + 1, 2, 2, "715a56")

func draw_engines(target: CanvasItem, online: bool, time: float) -> void:
	canvas = target
	for y in [62, 89]:
		plate([[232,y],[253,y],[262,y + 4],[262,y + 12],[252,y + 15],[232,y + 15]], "253a50", "bd826b")
		box(237, y + 2, 17, 11, "8ca4ac")
		for x in range(239, 253, 4):
			box(x, y + 3, 2, 9, "4c687e")
			box(x, y + 3, 1, 8, "bac7c3")
		box(254, y + 3, 5, 9, "183247")
		box(259, y + 4, 3, 7, "c5e5df")
		box(260, y + 5, 2, 5, "f1fff5" if online else "a4bfbd")
		box(236, y + 1, 19, 1, "c3cabc")
	# Docking lamps stay subtle while the white exhaust provides the motion.
	box(229, 83, 2, 2, "8ae5ce" if online else "b49b73")
