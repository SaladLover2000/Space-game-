extends Control
## Original procedural pixel art on a fixed low-resolution canvas.
var clock: float = 0.0
signal room_selected(id: String)
signal object_selected(room: String, index: int)
signal door_toggled(id: String, opened: bool)
var interactive: bool = false
var rooms: Dictionary = {}
var selected_room: String = ""
var hovered_room: String = ""
var camera := Rect2(0, 0, 280, 150)
var camera_tween: Tween
var reaction_left: float = 0.0
var upgrade_reaction: bool = false
const SpaceBackdrop = preload("res://assets/space_backdrop.gd")
var backdrop: RefCounted
var exterior: bool = false
const InteriorArt = preload("res://assets/interior_art.gd")
var interior_art: RefCounted
var selected_object: int = -1
var hovered_object: int = -1
var door_open: Dictionary = {"bridge": true, "engine": true}
var door_progress: Dictionary = {"bridge": 1.0, "engine": 1.0}

func _ready() -> void:
	custom_minimum_size = Vector2(560, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	backdrop = SpaceBackdrop.new()
	interior_art = InteriorArt.new()
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	Game.completed.connect(func(_credits: int, _xp: int): reaction_left = 4.0; upgrade_reaction = false)
	Game.repaired.connect(func(_id: String): reaction_left = 2.5; upgrade_reaction = true)
	mouse_exited.connect(func(): hovered_room = ""; hovered_object = -1; queue_redraw())
	tooltip_text = "Click a room to look inside" if interactive else ""

func _process(delta: float) -> void:
	clock += delta
	for id in door_open:
		door_progress[id] = move_toward(door_progress[id], 1.0 if door_open[id] else 0.0, delta * 3.0)
	reaction_left = maxf(0.0, reaction_left - delta)
	queue_redraw()

func room_bounds(id: String) -> Rect2:
	var b: Array = rooms[id].bounds
	return Rect2(b[0], b[1], b[2], b[3])

func view_transform() -> Transform2D:
	var scale_factor := minf(size.x / camera.size.x, size.y / camera.size.y)
	var origin := (size - camera.size * scale_factor) / 2.0 - camera.position * scale_factor
	return Transform2D(Vector2(scale_factor, 0), Vector2(0, scale_factor), origin) * ship_drift(clock)

func ship_drift(time: float) -> Transform2D:
	var angle := sin(time * 0.17) * 0.012
	var rotation := Transform2D(angle, Vector2.ZERO)
	var center := Vector2(140, 81)
	rotation.origin = center + Vector2(sin(time * 0.23) * 2, sin(time * 0.31) * 2) - rotation * center
	return rotation

func smoke_particle(index: int, time: float) -> Dictionary:
	var age := fposmod(time + index * 0.37, 4.0)
	return {"position": Vector2(250 + age * 10, 81 + sin(age * 1.7 + index) * age), "radius": 1 + floorf(age * 0.8), "alpha": (1.0 - age / 4.0) * 0.85}

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
	selected_object = -1
	hovered_object = -1
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
		hovered_object = object_at(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var door := door_at(event.position)
		if not door.is_empty():
			toggle_door(door)
			accept_event()
			return
		var object_index := object_at(event.position)
		if object_index >= 0:
			selected_object = object_index
			object_selected.emit(selected_room, object_index)
			accept_event()
			return
		var id := room_at(event.position)
		if not id.is_empty():
			room_selected.emit(id)
			accept_event()

func object_bounds(room: String, index: int) -> Rect2:
	var bounds: Array = rooms[room].object_bounds[index]
	return Rect2(bounds[0], bounds[1], bounds[2], bounds[3])

func object_at(local_position: Vector2) -> int:
	if exterior or selected_room.is_empty() or not Rect2(Vector2.ZERO, size).has_point(local_position):
		return -1
	var world := view_transform().affine_inverse() * local_position
	for index in range(rooms[selected_room].object_bounds.size()):
		if object_bounds(selected_room, index).has_point(world):
			return index
	return -1

func door_at(local_position: Vector2) -> String:
	if exterior or not Rect2(Vector2.ZERO, size).has_point(local_position):
		return ""
	var world := view_transform().affine_inverse() * local_position
	for id in door_open:
		var x: float = 91 if id == "bridge" else 168
		if Rect2(x, 72, 8, 31).has_point(world):
			return id
	return ""

func toggle_door(id: String) -> void:
	if not door_open.has(id):
		return
	door_open[id] = not door_open[id]
	door_toggled.emit(id, door_open[id])
	queue_redraw()

func draw_interior_selection() -> void:
	if not interactive:
		return
	if selected_room.is_empty():
		if not hovered_room.is_empty():
			draw_rect(room_bounds(hovered_room), Color("8ce8db"), false, 1)
		return
	var index := hovered_object if hovered_object >= 0 else selected_object
	if index >= 0:
		draw_rect(object_bounds(selected_room, index).grow(1), Color("f8d58d"), false, 1)

func expression() -> String:
	if reaction_left > 0:
		return "upgraded" if upgrade_reaction else "happy"
	if not Game.active.is_empty() and not Game.active.paused:
		return "charging"
	return "sad" if Game.state.battery < 20 else "idle"

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	draw_rect(Rect2(x, y, w, h), Color(color))

func _draw() -> void:
	if backdrop == null:
		return
	var bg_scale := size.y / 150.0
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * bg_scale)
	backdrop.draw(self, clock, size.x / bg_scale)
	draw_set_transform_matrix(view_transform())
	if exterior:
		draw_exterior()
	else:
		draw_interior()
	draw_smoke()

func draw_smoke() -> void:
	# Soft white vent wisps remain visible even while the damaged ship drifts.
	var count := 12 if "engine" in Game.state.owned else 7
	for i in range(count - 1, -1, -1):
		var puff := smoke_particle(i, clock)
		var p: Vector2 = puff.position.floor()
		var r: float = puff.radius
		var color := Color(0.94, 0.98, 1.0, puff.alpha)
		draw_rect(Rect2(p - Vector2(r, r - 1), Vector2(r * 2 + 1, r * 2 - 1)), color)
		draw_rect(Rect2(p - Vector2(r - 1, r), Vector2(r * 2 - 1, r * 2 + 1)), color)

func draw_exterior() -> void:
	box(25, 62, 218, 39, "16283e")
	box(15, 74, 15, 16, "53758b")
	box(11, 78, 9, 8, "85a9b7")
	box(20, 68, 230, 26, "53758b")
	box(29, 58, 205, 45, "7898a5")
	box(34, 61, 199, 38, "315671")
	box(39, 62, 178, 2, "a6c2bd")
	box(34, 90, 199, 9, "213b56")
	box(32, 62, 4, 33, "c9c3a0")
	box(42, 65, 35, 16, "112c49")
	box(45, 67, 28, 3, "73e0d9")
	box(45, 70, 3, 8, "329cb1")
	for x in range(90, 210, 24):
		box(x, 65, 13, 10, "132a45")
		box(x + 2, 67, 9, 6, "66d8d2" if "cockpit" in Game.state.owned else "537e95")
		box(x, 83, 16, 2, "7092a2")
	box(121, 57, 53, 4, "d3ad79")
	box(142, 48, 2, 10, "8bc7cc")
	box(140, 47, 6, 2, "f5d682")
	box(224, 68, 17, 25, "9caeb4")
	box(238, 73, 12, 16, "3d536b")
	box(248, 76, 3, 10, "dce9e5")
	box(39, 94, 183, 2, "4cd1c4")
	for x in range(80, 215, 13):
		box(x, 97, 7, 1, "182d49")
	if "engine" not in Game.state.owned:
		for x in [55, 115, 159, 205]:
			box(x, 88, 5, 2, "a66d63")
	# Small gold hull markings, not additional purchasable components.
	box(185, 89, 14, 2, "f3c576")
	box(187, 87, 2, 6, "f3c576")

func draw_interior() -> void:
	interior_art.draw(self, rooms, Game.state.owned, clock, door_progress)
	draw_interior_selection()
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
