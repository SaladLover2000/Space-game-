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
var camera := Rect2(-70, -45, 420, 240)
var camera_tween: Tween
var zoom_level: float = 1.0
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
const HullArt = preload("res://assets/hull_art.gd")
const RobotArt = preload("res://assets/robot_art.gd")
var hull_art := HullArt.new()
var robot_art := RobotArt.new()
var robot_position := Vector2(143, 103)
var robot_tween: Tween
var robot_destination := Vector2(143, 103)
var waiting_hatch: String = ""
var robot_walking: bool = false
const ROOM_CAMERA_SIZE = Vector2(420, 240)
const ShipComponents = preload("res://assets/ship_components.gd")
var components := ShipComponents.new()
signal part_selected(slot: String)
var workshop_mode: bool = false
var selected_slot: String = "engine"
var hovered_slot: String = ""
var preview_equipped: Dictionary = {}

func equipment() -> Dictionary:
	return preview_equipped if not preview_equipped.is_empty() else Game.state.equipped

func part_regions() -> Dictionary:
	return {"engine":[Rect2(232,60,33,47)], "wings":[Rect2(192,16,46,25), Rect2(190,119,49,24), Rect2(185,0,40,28), Rect2(152,127,75,28)], "antenna":[Rect2(157,16,28,28)], "hull":[Rect2(175,55,53,48)], "paint":[Rect2(103,61,50,35)], "lights":[Rect2(43,108,38,6)], "interior":[Rect2(35,62,54,35)]}

func part_at(local_position: Vector2) -> String:
	if not Rect2(Vector2.ZERO, size).has_point(local_position):
		return ""
	var world := view_transform().affine_inverse() * local_position
	for slot in part_regions():
		for region in part_regions()[slot]:
			if region.has_point(world):
				return slot
	return ""

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
	advance_robot(delta)
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

func smoke_particle(index: int, time: float, nozzle: int = 0) -> Dictionary:
	var age := fposmod(time + index * 0.37, 4.0)
	return {"position": Vector2(262 + age * 10, (69 if nozzle == 0 else 96) + sin(age * 1.7 + index) * age), "radius": 1 + floorf(age * 0.8), "alpha": (1.0 - age / 4.0) * 0.85}

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
	if not id.is_empty():
		follow_robot(id)

func change_zoom(factor: float) -> void:
	zoom_level = clampf(zoom_level * factor, 0.65, 2.8)
	var extent := Vector2(420, 240) / zoom_level
	camera = Rect2(Vector2(140, 75) - extent * 0.5, extent)
	queue_redraw()

func reset_zoom() -> void:
	zoom_level = 1.0
	change_zoom(1.0)

func follow_robot(id: String) -> void:
	var anchors := {"cockpit": Vector2(80, 103), "quarters": Vector2(143, 103), "engine": Vector2(205, 103)}
	if anchors.has(id):
		robot_destination = anchors[id]

func advance_robot(delta: float) -> void:
	var target := robot_destination
	waiting_hatch = ""
	var direction := signf(target.x - robot_position.x)
	var nearest: float = INF
	for hatch in door_open:
		var hatch_x: float = 95 if hatch == "bridge" else 172
		# Opening shutters must clear the doorway before the companion crosses.
		if door_open[hatch] and door_progress[hatch] >= 0.95:
			continue
		if (hatch_x - robot_position.x) * direction >= 0 and (target.x - hatch_x) * direction > 0:
			var distance_to_hatch := absf(hatch_x - robot_position.x)
			if distance_to_hatch < nearest:
				nearest = distance_to_hatch
				target.x = hatch_x - direction * 10.0
				# A hatch closing beside the robot must never pull it backwards.
				if (target.x - robot_position.x) * direction < 0:
					target.x = robot_position.x
				waiting_hatch = hatch
	var previous := robot_position
	robot_position = robot_position.move_toward(target, maxf(0.0, delta) * 150.0)
	robot_walking = not robot_position.is_equal_approx(previous)
func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		change_zoom(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
		accept_event()
		return
	if workshop_mode:
		if event is InputEventMouseMotion:
			hovered_slot = part_at(event.position)
			queue_redraw()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var slot := part_at(event.position)
			if not slot.is_empty():
				part_selected.emit(slot)
				accept_event()
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
	draw_rect(room_bounds(selected_room).grow(1), Color("7de1d6"), false, 1)
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
	hull_art.draw_engines(self, Game.state.engine_condition >= 25, clock)
	components.draw(self, equipment(), not exterior)
	draw_smoke()
	if workshop_mode:
		var slot := hovered_slot if not hovered_slot.is_empty() else selected_slot
		for region in part_regions().get(slot, []):
			draw_rect(region.grow(1), Color("f4d18b"), false, 1)

func draw_smoke() -> void:
	# Soft white vent wisps remain visible even while the damaged ship drifts.
	var count := 12 if Game.state.engine_condition >= 25 else 7
	for nozzle in range(2):
		for i in range(count - 1, -1, -1):
			var puff := smoke_particle(i, clock, nozzle)
			var p: Vector2 = puff.position.floor()
			var r: float = puff.radius
			var color := Color(0.94, 0.98, 1.0, puff.alpha)
			draw_rect(Rect2(p - Vector2(r, r - 1), Vector2(r * 2 + 1, r * 2 - 1)), color)
			draw_rect(Rect2(p - Vector2(r - 1, r), Vector2(r * 2 - 1, r * 2 + 1)), color)

func draw_exterior() -> void:
	hull_art.draw(self, Game.visual_repairs(), false)
func draw_interior() -> void:
	hull_art.draw(self, Game.visual_repairs(), true)
	interior_art.draw(self, rooms, Game.visual_repairs(), clock, door_progress, equipment().get("interior", "interior_stock"))
	draw_interior_selection()
	robot_art.draw(self, robot_position, clock, expression(), robot_walking, equipment())
