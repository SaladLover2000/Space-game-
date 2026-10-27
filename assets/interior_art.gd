extends RefCounted
## Original modular interior artwork; no reference sprites are embedded.
var canvas: CanvasItem
var theme_palette: Dictionary = {}

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	canvas.draw_rect(Rect2(x, y, w, h), Color(theme_palette.get(color, color)))

func screen(x: float, y: float, w: float, h: float, online: bool) -> void:
	box(x, y, w, h, "91abb6")
	box(x + 1, y + 1, w - 2, h - 2, "14283f")
	box(x + 2, y + 2, w - 4, 1, "76f0cc" if online else "79685a")
	for i in range(3):
		box(x + 2, y + 4 + i * 2, maxf(1, w - 6 - i * 2), 1, "308995" if online else "3e5261")

func draw(target: CanvasItem, rooms: Dictionary, owned: Array, time: float, doors: Dictionary, interior_theme: String = "interior_stock") -> void:
	canvas = target
	theme_palette = {}
	if interior_theme == "interior_habitat":
		theme_palette = {"1b2e43":"2c2a38", "476275":"685853", "354755":"4d4044", "607d89":"8c7969", "415565":"63515a", "92a5a9":"c8b797", "586b75":"897873", "4a6371":"655552", "34434e":"3e3642", "304959":"433840", "3b5668":"675e58", "2d3c4d":"443a43", "69828b":"a49375", "43515e":"756366", "a8f4d5":"ffe3a2", "9db1b5":"c6b89d", "7994a1":"a8957d"}
	elif interior_theme == "interior_lab":
		theme_palette = {"1b2e43":"0c2037", "476275":"304861", "354755":"25334d", "607d89":"4a6580", "415565":"344665", "92a5a9":"91c3cf", "586b75":"5c8098", "4a6371":"354e69", "34434e":"20314b", "304959":"223b54", "3b5668":"324d68", "2d3c4d":"20314b", "69828b":"65a1b9", "a8f4d5":"81f2f0", "9db1b5":"accbd4", "7994a1":"608a9f"}
	# Pressure-hull rim sits inside the shared shaped exterior chassis.
	for frame in [Rect2(31, 51, 64, 56), Rect2(97, 54, 73, 53), Rect2(173, 50, 65, 58)]:
		box(frame.position.x, frame.position.y, frame.size.x, frame.size.y, "1b2e43")
		box(frame.position.x, frame.position.y, frame.size.x, 2, "9db1b5")
		box(frame.position.x, frame.end.y - 2, frame.size.x, 2, "7994a1")
	for id in rooms:
		var b: Array = rooms[id].bounds
		var x: int = int(b[0])
		var width: int = int(b[2])
		var fixed: bool = id in owned
		# Repeated wall modules and recessed steel floor tiles.
		box(x, 55, width, 47, "476275" if fixed else "354755")
		for px in range(x + 1, x + width - 2, 10):
			box(px, 57, 9, 41, "607d89" if fixed else "415565")
			box(px + 1, 58, 7, 1, "92a5a9" if fixed else "586b75")
			box(px + 1, 61, 1, 34, "4a6371" if fixed else "34434e")
			box(px + 2, 95, 6, 1, "304959")
		# A thin horizontal deck, with tall walls rather than a top-down floor grid.
		for py in range(99, 103, 4):
			for px in range(x + 1, x + width - 2, 8):
				box(px, py, 7, 4, "3b5668" if fixed else "2d3c4d")
				box(px + 1, py, 5, 1, "69828b" if fixed else "43515e")
				box(px + 6, py + 1, 1, 3, "1d3045")
		box(x + 1, 98, width - 3, 1, "92a5a9" if fixed else "586b75")
		box(x + 7, 58, width - 15, 1, "a8f4d5" if fixed else "8c7257")
		if not fixed:
			for i in range(4):
				box(x + 4 + i * 12, 86 + i % 3 * 6, 3, 1, "8b6256")
	# Cockpit: panoramic glass, workstation, monitors, pilot seat and vent.
	var bridge: bool = "cockpit" in owned
	box(35, 59, 37, 19, "a6b6b9")
	box(37, 61, 33, 15, "15384d")
	box(39, 62, 29, 2, "70cfd1" if bridge else "50798c")
	box(39, 64, 2, 10, "417e96")
	box(52, 62, 1, 14, "8ca7af")
	for i in range(9):
		box(42 + i * 3 % 25, 65 + i * 7 % 9, 1, 1, "a3e7dc" if bridge else "688b9d")
	box(36, 79, 33, 12, "8197a0")
	box(38, 81, 29, 6, "20364b")
	screen(39, 80, 13, 8, bridge)
	screen(54, 80, 12, 8, bridge)
	box(39, 89, 27, 2, "47596a")
	for px in range(39, 66, 4):
		box(px, 88, 2, 1, "69decb" if bridge else "9b825c")
	box(76, 78, 8, 15, "183047")
	box(77, 77, 6, 13, "4eabb0" if bridge else "637386")
	box(73, 90, 13, 5, "79b8b4" if bridge else "7d8792")
	box(79, 95, 2, 5, "b0b9b7")
	box(75, 100, 10, 1, "24354a")
	screen(77, 61, 12, 13, bridge)
	# Quarters: recessed bunk, locker, shelf, lamp, dock and supplies.
	var cozy: bool = "quarters" in owned
	box(100, 74, 30, 25, "1d3047")
	box(102, 76, 26, 21, "9ca9ae")
	box(104, 78, 22, 16, "234459")
	box(104, 79, 21, 12, "519db3" if cozy else "706b88")
	box(105, 79, 7, 5, "d1d8cc" if cozy else "a09f9f")
	box(113, 83, 12, 1, "81c3c4" if cozy else "89839b")
	box(104, 94, 23, 2, "536f81")
	box(102, 67, 26, 5, "526e7c")
	box(104, 68, 8, 2, "83b8bb" if cozy else "6a7584")
	box(116, 68, 9, 2, "9aaca3")
	box(132, 59, 32, 3, "9ba9aa")
	box(134, 62, 2, 3, "345062")
	box(160, 62, 2, 3, "345062")
	box(137, 54, 5, 5, "a78e69")
	box(145, 55, 3, 4, "6788a1")
	box(154, 55, 5, 4, "d6ad7e" if cozy else "777572")
	if cozy:
		box(156, 50, 1, 6, "8cdb98")
		box(153, 51, 3, 2, "69c9a3")
		box(157, 49, 3, 2, "b0e8a2")
	box(157, 68, 8, 22, "7b96a0")
	box(158, 69, 6, 19, "3a596e")
	box(159, 71, 4, 1, "90a7b0")
	box(159, 80, 1, 3, "c7cfbc")
	box(139, 65, 1, 7, "bec3b5" if cozy else "815f55")
	box(136, 71, 7, 2, "ffe7a0" if cozy else "887963")
	box(132, 99, 23, 3, "20394b")
	for px in range(134, 153, 4):
		box(px, 100, 2, 1, "73c4c0" if cozy else "607d89")
	# Engine: fuel cells, braced reactor, service terminal, conduit and vents.
	var powered: bool = "engine" in owned
	box(185, 67, 34, 31, "263748")
	box(187, 69, 30, 27, "a0afb2")
	box(189, 71, 26, 23, "1c3443")
	for px in range(191, 214, 6):
		box(px, 74, 3, 17, "73e4c7" if powered else "84604b")
		box(px, 75, 1, 14, "c7ffe4" if powered else "af8361")
		box(px - 1, 72, 5, 2, "687f88")
		box(px - 1, 91, 5, 2, "687f88")
	for px in [187, 215]:
		box(px, 69, 2, 2, "d8d8c0")
		box(px, 94, 2, 2, "d8d8c0")
	box(221, 60, 7, 34, "233b4a")
	box(222, 62, 5, 30, "5892a1" if powered else "58636a")
	box(223, 65, 2, 24, "97e0da" if powered else "7b7c75")
	for py in range(65, 92, 7):
		box(221, py, 7, 2, "b4b9ac")
	box(228, 77, 14, 9, "8498a2")
	box(240, 74, 10, 15, "35445a")
	screen(175, 82, 9, 15, powered)
	box(178, 61, 39, 3, "47677a")
	box(180, 62, 36, 1, "76cbbc" if powered else "8a6b58")
	for px in range(187, 218, 5):
		box(px, 100, 3, 2, "ddba70")
	# Theme-specific side-wall fittings; cosmetic layers do not grant repairs.
	if interior_theme == "interior_lab":
		box(157, 68, 9, 25, "1b344b")
		box(159, 71, 5, 18, "4fabc4")
		box(160, 72, 1, 15, "b7f7ed")
		box(157, 68, 9, 3, "9abec7")
		box(157, 90, 9, 3, "91aab8")
		screen(130, 77, 12, 8, true)
		for px in [106, 137, 178, 226]:
			box(px, 97, 5, 1, "72e5df")
	elif interior_theme == "interior_habitat":
		box(136, 71, 7, 2, "ffe5a2")
		box(137, 73, 5, 1, "c19a72")
		for px in [105, 121, 154]:
			box(px, 99, 4, 1, "e7c58d")
	# Animated bulkhead shutters connect cockpit → quarters → engine.
	for id in doors:
		var x: int = 91 if id == "bridge" else 168
		var openness: float = doors[id]
		box(x, 73, 8, 30, "142638")
		box(x, 72, 8, 2, "b3c0b8")
		box(x, 74, 1, 29, "7f9ba5")
		box(x + 7, 74, 1, 29, "7f9ba5")
		var shutter := ceilf(3.0 * (1.0 - openness))
		if shutter > 0:
			box(x + 1, 75, shutter, 26, "768b96")
			box(x + 7 - shutter, 75, shutter, 26, "768b96")
		box(x + 1, 101, 6, 2, "e3bd73")
		box(x + 6, 69, 2, 2, "7fe8be" if openness > 0.9 else "e2a770")
