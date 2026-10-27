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
	# Three different pressure volumes: raised bridge, narrow waist, broad reactor.
	plate([[7,80],[23,55],[43,40],[77,40],[98,52],[157,52],[175,42],[217,42],[239,58],[254,76],[254,98],[236,111],[213,121],[176,121],[156,110],[107,110],[91,116],[43,116],[22,100]], "17283e", "a3b9bf")
	plate([[11,80],[27,58],[44,44],[76,44],[97,56],[158,56],[176,46],[216,46],[236,61],[249,78],[249,96],[234,107],[212,117],[178,117],[157,106],[106,106],[90,112],[44,112],[26,97]], "788e99", "bd826b")
	plate([[16,81],[32,61],[46,48],[74,48],[95,59],[160,59],[178,50],[214,50],[231,64],[244,79],[244,93],[229,104],[211,112],[181,112],[157,102],[105,102],[87,108],[46,108],[30,94]], "334f68", "b5c5c3")
	# Separate belly plates avoid an unbroken rectangular border across the ship.
	plate([[29,95],[46,105],[88,105],[98,101],[90,112],[44,112]], "263b53", "79939e")
	plate([[106,104],[155,104],[166,109],[109,109]], "283e55", "859ca4")
	plate([[171,104],[231,101],[214,116],[180,116]], "263b53", "8da5ab")
	box(46, 44, 28, 2, "ced3c2")
	box(106, 54, 46, 2, "acbdba")
	box(179, 46, 34, 2, "c9cebd")
	for x in range(47, 79, 7):
		box(x, 45, 1, 1, "f0e4c7")
	for x in range(181, 217, 7):
		box(x, 47, 1, 1, "f0e4c7")
	# Recessed keel, docking sockets, cable runs and service lights.
	for x in [49, 73, 116, 141, 184, 205]:
		box(x, 108 if x < 90 else 115 if x > 170 else 107, 5, 2, "182e43")
		box(x + 1, 108 if x < 90 else 115 if x > 170 else 107, 2, 1, "b1a581")
	box(176, 113, 27, 1, "62babb")
	box(44, 109, 35, 1, "69b6bb")
	for x in [89, 161]:
		plate([[x,53],[x + 7,57],[x + 7,103],[x,108]], "354b61", "bd826b")
		for y in range(61, 101, 8):
			box(x + 2, y, 3, 2, "9cafb1")
	# Low dorsal module and a short communications mast.
	plate([[98,48],[104,41],[133,41],[140,48]], "748c99", "bd826b")
	box(106, 42, 24, 2, "c5cebf")
	box(146, 43, 2, 6, "7396a4")
	box(145, 41, 4, 2, "e6ca84")
	box(170, 38, 2, 9, "7ca2b1")
	plate([[163,36],[165,32],[177,32],[179,36],[175,39],[167,39]], "678b9e", "b9c8c2")
	box(168, 34, 6, 1, "77d9d3")
	# Exterior maintenance fittings remain visible around the cutaway too.
	for x in range(183, 216, 6):
		box(x, 52, 4, 2, "1e354c")
		box(x, 52, 3, 1, "a8b8b5")
	box(107, 47, 24, 2, "344f63")
	for x in range(109, 130, 4):
		box(x, 46, 2, 2, "a1b3b2")
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
	# Waist module: paired windows, service hatch, conduits and ribbed radiator.
	plate([[102,61],[147,61],[155,67],[155,94],[145,100],[107,100],[102,94]], "637f8f", "b9c7c2")
	box(107, 63, 37, 2, "9fb9bb")
	for x in [110, 131]:
		plate([[x,68],[x + 13,68],[x + 15,71],[x + 15,79],[x,79]], "183247", "8ba9b3")
		box(x + 2, 70, 10, 6, "76d8ce" if "cockpit" in owned else "477d99")
		box(x + 2, 70, 2, 4, "a7e4d9")
	box(112, 84, 15, 13, "2d455b")
	box(114, 86, 11, 9, "8a9faa")
	box(121, 89, 2, 3, "c8c5a6")
	for y in range(85, 98, 3):
		box(133, y, 16, 1, "263e54")
		box(134, y, 14, 1, "416b7d")
	# Reactor pod: chamfered access casing and radial braces, not repeated boxes.
	plate([[177,56],[211,56],[223,66],[223,95],[210,108],[180,108],[171,98],[171,65]], "79929f", "c3cdc2")
	plate([[182,62],[207,62],[216,70],[216,91],[207,101],[183,101],[177,94],[177,70]], "29465d", "9cbbc0")
	plate([[186,67],[203,67],[210,74],[210,88],[203,95],[186,95],[182,90],[182,73]], "416b7b", "6f98a4")
	for x in range(187, 207, 5):
		box(x, 74, 2, 15, "8ce8ce" if "engine" in owned else "70878e")
		box(x, 74, 1, 12, "b0efdb" if "engine" in owned else "9b9d8f")
	for p in [Vector2(178,64), Vector2(214,67), Vector2(178,97), Vector2(211,98)]:
		box(p.x, p.y, 2, 2, "cbbf9f")
	# Exposed copper/teal utility lines tie the volumes together.
	box(79, 94, 25, 2, "be8d6e")
	box(99, 94, 2, 9, "be8d6e")
	box(151, 90, 21, 2, "70b9b8")
	box(157, 65, 11, 2, "718e9e")
	box(160, 65, 2, 24, "718e9e")
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
