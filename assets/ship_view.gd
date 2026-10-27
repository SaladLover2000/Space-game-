extends Control
## Original procedural pixel art on a fixed low-resolution canvas.
var clock: float = 0.0
signal room_selected(id: String)
var interactive: bool = false
var rooms: Dictionary = {}
var selected_room: String = ""
var hovered_room: String = ""
var camera := Rect2(0, 0, 280, 150)
var camera_tween: Tween
var reaction_left: float = 0.0
var upgrade_reaction: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(560, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	Game.completed.connect(func(_credits: int, _xp: int): reaction_left = 4.0; upgrade_reaction = false)
	Game.repaired.connect(func(_id: String): reaction_left = 2.5; upgrade_reaction = true)
	mouse_exited.connect(func(): hovered_room = ""; queue_redraw())
	tooltip_text = "Click a room to look inside" if interactive else ""

func _process(delta: float) -> void:
	clock += delta
	reaction_left = maxf(0.0, reaction_left - delta)
	queue_redraw()

func room_bounds(id: String) -> Rect2:
	var b: Array = rooms[id].bounds
	return Rect2(b[0], b[1], b[2], b[3])

func view_transform() -> Transform2D:
	var scale_factor := minf(size.x / camera.size.x, size.y / camera.size.y)
	var origin := (size - camera.size * scale_factor) / 2.0 - camera.position * scale_factor
	return Transform2D(Vector2(scale_factor, 0), Vector2(0, scale_factor), origin)

func room_at(local_position: Vector2) -> String:
	if not Rect2(Vector2.ZERO, size).has_point(local_position):
		return ""
	var world := view_transform().affine_inverse() * local_position
	for id in rooms:
		if room_bounds(id).has_point(world):
			return id
	return ""

func focus_room(id: String) -> void:
	if not id.is_empty() and not rooms.has(id):
		return
	selected_room = id
	var target := Rect2(0, 0, 280, 150)
	if not id.is_empty():
		target = Rect2(room_bounds(id).get_center() - Vector2(56, 30), Vector2(112, 60))
	if camera_tween:
		camera_tween.kill()
	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_method(func(value: Rect2): camera = value; queue_redraw(), camera, target, 0.5)

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseMotion:
		hovered_room = room_at(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var id := room_at(event.position)
		if not id.is_empty():
			room_selected.emit(id)
			accept_event()

func expression() -> String:
	if reaction_left > 0:
		return "upgraded" if upgrade_reaction else "happy"
	if not Game.active.is_empty() and not Game.active.paused:
		return "charging"
	return "sad" if Game.state.battery < 20 else "idle"

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	draw_set_transform_matrix(view_transform())
	box(0, 0, 280, 150, "091124")
	# Dithered nebula layers sit farther away than the bright stars.
	for i in range(70):
		var nx := fposmod(i * 11.3 - clock * 0.12, 150)
		var ny := 15 + fposmod(i * 17.7, 85)
		if Vector2(nx - 74, ny - 57).length() < 47:
			box(floorf(nx), floorf(ny), 3, 2, "11182e" if i % 2 else "111c32")
	for i in range(85):
		var x := fposmod(i * 67.3 - clock * (0.3 + i % 3 * 0.3), 280)
		var y := fposmod(i * 31.7, 150)
		box(floorf(x), floorf(y), 1, 1, "34536d" if i % 3 else "93b8c5")
	box(216, 14, 26, 26, "243053")
	box(212, 20, 34, 14, "243053")
	box(220, 14, 7, 4, "3a4869")
	var repaired: bool = "engine" in Game.state.owned
	var bridge_fixed: bool = "cockpit" in Game.state.owned
	var quarters_fixed: bool = "quarters" in Game.state.owned
	box(28, 48, 218, 66, "35445a")
	box(20, 58, 234, 46, "35445a")
	box(28, 51, 213, 57, "151e30")
	box(33, 56, 60, 46, "1c3e50" if bridge_fixed else "17293a")
	box(97, 56, 73, 46, "2b3a50" if quarters_fixed else "20283b")
	box(174, 56, 62, 46, "173339" if repaired else "302730")
	for x in range(34, 235, 8):
		box(x, 104, 6, 4, "657083")
		box(x, 51, 6, 2, "516177")
	for x in range(37, 235, 12):
		box(x, 109, 8, 1, "273449")
	for x in [94, 171]:
		box(x, 58, 2, 43, "526070")
		box(x, 72, 2, 5, "d1b779")
	box(81, 61, 7, 12, "243f50")
	box(83, 63, 3, 3, "7bcfbe" if bridge_fixed else "7b6452")
	box(83, 68, 3, 1, "8da2ad")
	# Cockpit glass, console and chair.
	box(36, 59, 28, 22, "28485d")
	box(38, 61, 24, 2, "5f98a7")
	box(38, 63, 2, 15, "4d7e93")
	box(39, 85, 36, 7, "405267")
	box(41, 86, 9, 2, "65cfbd")
	box(55, 86, 4, 2, "be9b57")
	box(67, 76, 7, 20, "596074")
	box(61, 91, 13, 5, "596074")
	if bridge_fixed:
		box(38, 63, 24, 16, "32677a")
		box(40, 65, 1, 11, "85dbdf")
		box(43, 66, 2, 2, "d5e9dd")
		box(54, 73, 1, 1, "d5e9dd")
		box(41, 85, 26, 5, "194958")
		for x in range(42, 66, 5):
			box(x, 86, 3, 2, "79ddcc")
		box(68, 77, 5, 15, "4b969d")
		box(62, 91, 11, 3, "4b969d")
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
	if quarters_fixed:
		box(104, 81, 23, 7, "569cab")
		box(105, 81, 6, 5, "d1d9cd")
		box(132, 56, 9, 16, "2b3a50")
		box(138, 68, 5, 2, "ffe1a3")
		box(140, 64, 1, 4, "96b5bc")
		box(149, 60, 6, 4, "be9973")
		box(151, 55, 2, 6, "69bd8e")
		box(148, 56, 3, 2, "83d69d")
		box(153, 54, 3, 2, "83d69d")
		box(156, 91, 10, 11, "2b3a50")
		box(132, 101, 24, 2, "66afab")
	# Engine shares the purchased repair state with the economy.
	box(183, 67, 37, 30, "52606d")
	box(188, 71, 27, 22, "162730")
	box(179, 62, 48, 2, "476575" if repaired else "634c47")
	box(225, 63, 2, 30, "476575" if repaired else "634c47")
	box(224, 91, 8, 2, "476575" if repaired else "634c47")
	box(177, 86, 4, 12, "405163")
	box(178, 88, 2, 2, "90d6b3" if repaired else "a77a58")
	box(178, 93, 2, 1, "90d6b3" if repaired else "a77a58")
	for x in [184, 216]:
		box(x, 68, 2, 2, "9aabb4")
		box(x, 94, 2, 2, "9aabb4")
	for x in range(186, 221, 5):
		box(x, 99, 3, 2, "c7af68")
	for x in range(191, 214, 6):
		box(x, 74, 3, 16, "60ddca" if repaired else "755347")
	box(220, 77, 20, 9, "68788a")
	box(240, 74, 10, 15, "35445a")
	if repaired:
		box(250, 78, 8 + int(sin(clock * 9) * 2), 7, "e4cf7a")
		box(250, 80, 14 + int(sin(clock * 9) * 2), 3, "66ddde")
	for id in rooms:
		var bounds := room_bounds(id)
		if id not in Game.state.owned:
			for i in range(3):
				box(bounds.position.x + 3 + i * 16, 99 - i % 3 * 4, 4, 2, "865e4c")
			# Failing strip light flickers without strobing the entire room.
			box(bounds.position.x + 22, 57, 14, 1, "887357" if fmod(clock + bounds.position.x, 5.0) > 0.7 else "493d3d")
		else:
			box(bounds.position.x + 22, 57, 14, 1, "a7ead9")
		if interactive and id == hovered_room:
			draw_rect(bounds.grow(1), Color("7de1d6"), false, 1)
	# Tiny companion: bob, blink, battery-sensitive eyes.
	var mood := expression()
	var y := 84 + int(sin(clock * 2) > 0)
	if mood in ["happy", "upgraded"]:
		y -= int(abs(sin(clock * 9)) * 3)
	if mood == "sad":
		y += 1
	box(137, y + 9, 13, 9, "9aadb7")
	box(134, y + 10, 3, 8, "667e91")
	box(150, y + (5 if mood in ["happy", "upgraded"] else 10), 3, 8, "667e91")
	box(137, y + 18, 4, 3, "506579")
	box(146, y + 18, 4, 3, "506579")
	box(135, y, 17, 11, "b1bbc1")
	box(137, y + 2, 13, 7, "152c3d")
	var eye := "70e8d4" if mood != "sad" else "6d9da8"
	var eye_height := 1 if fmod(clock, 4) > 3.8 or mood == "sad" else 3
	box(139, y + 4, 3, eye_height, eye)
	box(145, y + 4, 3, eye_height, eye)
	box(143, y - 3, 1, 3, "8293a2")
	box(142, y - 4, 3, 2, "e4c777")
	if mood in ["happy", "upgraded"]:
		box(140, y + 3, 1, 1, "152c3d")
		box(146, y + 3, 1, 1, "152c3d")
		box(156, y - 2, 1, 5, "e8d48b")
		box(154, y, 5, 1, "e8d48b")
	if mood == "charging":
		box(132, 103, 24, 2, "50bfae")
		box(142, y + 13, 4, 3, "9af0c9" if fmod(clock, 1.2) < 0.8 else "538f88")
		box(155, y + 5 - int(fmod(clock * 5, 8)), 1, 2, "93eac9")
