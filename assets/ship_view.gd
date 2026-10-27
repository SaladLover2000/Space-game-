extends Control
## Original procedural pixel art on a fixed low-resolution canvas.
var clock: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(560, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	var scale_factor := minf(size.x / 280.0, size.y / 150.0)
	draw_set_transform(Vector2((size.x - 280 * scale_factor) / 2, 0), 0, Vector2.ONE * scale_factor)
	box(0, 0, 280, 150, "091124")
	for i in range(85):
		var x := fposmod(i * 67.3 - clock * (0.3 + i % 3 * 0.3), 280)
		var y := fposmod(i * 31.7, 150)
		box(floorf(x), floorf(y), 1, 1, "34536d" if i % 3 else "93b8c5")
	box(216, 14, 26, 26, "243053")
	box(212, 20, 34, 14, "243053")
	box(220, 14, 7, 4, "3a4869")
	var repaired: bool = "engine" in Game.state.owned
	box(28, 48, 218, 66, "35445a")
	box(20, 58, 234, 46, "35445a")
	box(28, 51, 213, 57, "151e30")
	box(33, 56, 60, 46, "17293a")
	box(97, 56, 73, 46, "20283b")
	box(174, 56, 62, 46, "173339" if repaired else "302730")
	for x in range(34, 235, 8):
		box(x, 104, 6, 4, "657083")
		box(x, 51, 6, 2, "516177")
	# Cockpit glass, console and chair.
	box(36, 59, 28, 22, "28485d")
	box(38, 61, 24, 2, "5f98a7")
	box(38, 63, 2, 15, "4d7e93")
	box(39, 85, 36, 7, "405267")
	box(41, 86, 9, 2, "65cfbd")
	box(55, 86, 4, 2, "be9b57")
	box(67, 76, 7, 20, "596074")
	box(61, 91, 13, 5, "596074")
	# Bunk, shelf, dangling cable, abandoned boxes.
	box(102, 79, 27, 18, "435168")
	box(104, 81, 23, 7, "79738b")
	box(105, 81, 6, 5, "a6a8ac")
	box(104, 89, 24, 5, "3b4565")
	box(138, 62, 21, 3, "566071")
	box(140, 58, 5, 4, "74715e")
	box(150, 57, 4, 5, "456d75")
	box(132, 56, 1, 14, "956258")
	box(132, 70, 8, 1, "956258")
	box(156, 91, 10, 11, "68504b")
	# Engine shares the purchased repair state with the economy.
	box(183, 67, 37, 30, "52606d")
	box(188, 71, 27, 22, "162730")
	for x in range(191, 214, 6):
		box(x, 74, 3, 16, "60ddca" if repaired else "755347")
	box(220, 77, 20, 9, "68788a")
	box(240, 74, 10, 15, "35445a")
	if repaired:
		box(250, 78, 8 + int(sin(clock * 9) * 2), 7, "e4cf7a")
		box(250, 80, 14 + int(sin(clock * 9) * 2), 3, "66ddde")
	else:
		for i in range(8):
			box(36 + i * 26, 99 - i % 3 * 5, 4, 2, "865e4c")
	# Tiny companion: bob, blink, battery-sensitive eyes.
	var y := 84 + int(sin(clock * 2) > 0)
	box(137, y + 9, 13, 9, "9aadb7")
	box(134, y + 10, 3, 8, "667e91")
	box(150, y + 10, 3, 8, "667e91")
	box(137, y + 18, 4, 3, "506579")
	box(146, y + 18, 4, 3, "506579")
	box(135, y, 17, 11, "b1bbc1")
	box(137, y + 2, 13, 7, "152c3d")
	var eye := "70e8d4" if Game.state.battery > 20 else "6d9da8"
	var eye_height := 1 if fmod(clock, 4) > 3.8 or Game.state.battery < 20 else 3
	box(139, y + 4, 3, eye_height, eye)
	box(145, y + 4, 3, eye_height, eye)
	box(143, y - 3, 1, 3, "8293a2")
	box(142, y - 4, 3, 2, "e4c777")
