extends Control
## Original procedural pixel art on a fixed low-resolution canvas.
var clock: float = 0.0
signal seating_changed(seated: bool)
const PILOT_SEAT = Vector2(58, 103)
const PILOT_CUSHION_Y = 91.0
const DRAG_THRESHOLD = 6.0
var robot_seated: bool = false
var seat_requested: bool = false
var pan_pressed: bool = false
var pan_dragging: bool = false
var pan_press_position := Vector2.ZERO
var pan_start_camera := Rect2()
var pan_scale: float = 1.0
signal room_selected(id: String)
signal object_selected(room: String, index: int)
signal door_toggled(id: String, opened: bool)
var interactive: bool = false
var rooms: Dictionary = {}
var selected_room: String = ""
var hovered_room: String = ""
var camera := Rect2(-70, -45, 420, 240)
var camera_tween: Tween
var preview_expansion: String = ""
var manual_hold: float = 5.0
var autonomous_activity: String = "resting"
var activity_clock: float = 0.0
var layout_key: String = ""
var robot_route: Array[Vector2] = []
const ExpansionArt = preload("res://assets/expansion_art.gd")
var expansion_art := ExpansionArt.new()
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
const PixelShipArt = preload("res://assets/pixel_ship_art.gd")
var pixel_ship_art := PixelShipArt.new()
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
	return {"engine":[Rect2(232,60,33,47), Rect2(268,50,32,65)], "wings":[Rect2(192,16,46,25), Rect2(190,119,49,24), Rect2(185,0,40,28), Rect2(152,127,75,28)], "antenna":[Rect2(157,16,28,28)], "hull":[Rect2(175,55,53,48)], "paint":[Rect2(103,61,50,35)], "lights":[Rect2(43,108,38,6)], "interior":[Rect2(35,62,54,35)]}

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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	sync_layout()
	Game.changed.connect(sync_layout)
	backdrop = SpaceBackdrop.new()
	interior_art = InteriorArt.new()
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	Game.completed.connect(func(_credits: int, _xp: int): reaction_left = 4.0; upgrade_reaction = false)
	Game.repaired.connect(func(_id: String): reaction_left = 2.5; upgrade_reaction = true)
	mouse_exited.connect(func(): hovered_room = ""; hovered_object = -1; queue_redraw())
	tooltip_text = "Drag with left mouse to pan. Mouse wheel zooms. Click the pilot seat to sit."
	get_window().focus_exited.connect(cancel_pan)

func _process(delta: float) -> void:
	clock += delta
	advance_autonomy(delta)
	advance_robot(delta)
	for id in door_open:
		door_progress[id] = move_toward(door_progress[id], 1.0 if door_open[id] else 0.0, delta * 3.0)
	reaction_left = maxf(0.0, reaction_left - delta)
	queue_redraw()

func room_bounds(id: String) -> Rect2:
	var b: Array = rooms[id].bounds
	return Rect2(b[0], b[1], b[2], b[3])

func camera_transform() -> Transform2D:
	var scale_factor := minf(size.x / camera.size.x, size.y / camera.size.y)
	var origin := (size - camera.size * scale_factor) / 2.0 - camera.position * scale_factor
	return Transform2D(Vector2(scale_factor,0),Vector2(0,scale_factor),origin)

func view_transform() -> Transform2D:
	return camera_transform()*ship_drift(clock)

func ship_drift(time: float) -> Transform2D:
	var angle := sin(time * 0.17) * 0.012
	var rotation := Transform2D(angle, Vector2.ZERO)
	var center := Vector2(140, 81)
	rotation.origin = center + Vector2(sin(time * 0.23) * 2, sin(time * 0.31) * 2) - rotation * center
	return rotation

func smoke_particle(index: int, time: float, nozzle: int = 0) -> Dictionary:
	var age := fposmod(time + index * 0.37, 4.0)
	return {"position": Vector2(294 + age * 10, (66 if nozzle == 0 else 100) + sin(age * 1.7 + index) * age), "radius": 1 + floorf(age * 0.8), "alpha": (1.0 - age / 4.0) * 0.85}

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
	var extent := fitted_camera().size / zoom_level
	camera = Rect2(camera.get_center() - extent * 0.5, extent)
	queue_redraw()

func reset_zoom() -> void:
	cancel_pan()
	camera = fitted_camera()
	zoom_level = 1.0
	change_zoom(1.0)

func follow_robot(id: String) -> void:
	manual_hold = 60.0
	var anchors := {"cockpit": Vector2(80, 103), "quarters": Vector2(143, 103), "engine": Vector2(205, 103)}
	if anchors.has(id):
		if robot_seated or seat_requested:
			stand_up()
		set_robot_route(anchors[id])
	elif rooms.has(id) and id in Game.state.expansions:
		stand_up()
		var item: Dictionary = Game.catalog_item(Game.expansion_catalog,id)
		set_robot_route(Vector2(item.anchor[0],item.anchor[1]))

func request_sit() -> void:
	manual_hold = 120.0
	robot_seated = false
	seat_requested = true
	set_robot_route(PILOT_SEAT)
	seating_changed.emit(false)

func stand_up() -> void:
	manual_hold = 60.0
	robot_seated = false
	seat_requested = false
	robot_destination = robot_position
	robot_route.clear()
	robot_walking = false
	waiting_hatch = ""
	seating_changed.emit(false)

func toggle_seat() -> void:
	if robot_seated or seat_requested:
		stand_up()
	else:
		request_sit()

func seated_origin() -> Vector2:
	var id: String = robot_art.resolve("robot_legs",equipment())
	return Vector2(PILOT_SEAT.x,PILOT_CUSHION_Y+robot_art.part_size(id,"left").y-1.0)

func advance_robot(delta: float) -> void:
	if robot_seated:
		robot_walking = false
		return
	var target := robot_destination
	waiting_hatch = ""
	var direction := signf(target.x - robot_position.x)
	var nearest: float = INF
	var body_clearance: float = robot_art.clearance(equipment())
	for hatch in door_open:
		if robot_position.y > 110 or target.y > 110:
			continue
		var hatch_x: float = 95 if hatch == "bridge" else 172
		# Opening shutters must clear the doorway before the companion crosses.
		if door_open[hatch] and door_progress[hatch] >= 0.95:
			continue
		if (hatch_x - robot_position.x) * direction >= 0 and (target.x - hatch_x) * direction > 0:
			var distance_to_hatch := absf(hatch_x - robot_position.x)
			if distance_to_hatch < nearest:
				nearest = distance_to_hatch
				target.x = hatch_x - direction * body_clearance
				# A hatch closing beside the robot must never pull it backwards.
				if (target.x - robot_position.x) * direction < 0:
					target.x = robot_position.x
				waiting_hatch = hatch
	var previous := robot_position
	robot_position = robot_position.move_toward(target, maxf(0.0, delta) * 150.0 * (1.0+Game.equipment_effects().move_percent/100.0))
	robot_walking = not robot_position.is_equal_approx(previous)
	if robot_position.distance_to(robot_destination) < 0.01 and not robot_route.is_empty():
		robot_destination = robot_route.pop_front()
	if seat_requested and robot_route.is_empty() and robot_position.distance_to(PILOT_SEAT) < 0.01:
		robot_seated = true
		seat_requested = false
		robot_walking = false
		seating_changed.emit(true)

func cancel_pan() -> void:
	pan_pressed = false
	pan_dragging = false
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			cancel_pan()
			change_zoom(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.15)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pan_pressed = true
				pan_dragging = false
				pan_press_position = event.position
				pan_start_camera = camera
				pan_scale = minf(size.x/camera.size.x,size.y/camera.size.y)
			else:
				var is_click: bool = pan_pressed and not pan_dragging and event.position.distance_to(pan_press_position) < DRAG_THRESHOLD
				cancel_pan()
				if is_click and Rect2(Vector2.ZERO,size).has_point(event.position):
					activate_at(event.position)
			accept_event()
			return
	if event is InputEventMouseMotion:
		if pan_pressed:
			if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
				cancel_pan()
				return
			if event.position.distance_to(pan_press_position) >= DRAG_THRESHOLD:
				pan_dragging = true
			if pan_dragging:
				camera.position = pan_start_camera.position - (event.position-pan_press_position)/maxf(pan_scale,0.001)
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				queue_redraw()
			accept_event()
			return
		if workshop_mode:
			hovered_slot = part_at(event.position)
		elif interactive:
			hovered_room = room_at(event.position)
			hovered_object = object_at(event.position)
		queue_redraw()

func activate_at(local_position: Vector2) -> void:
	if not interactive:
		return
	if workshop_mode:
		var slot := part_at(local_position)
		if not slot.is_empty():
			part_selected.emit(slot)
		return
	var door := door_at(local_position)
	if not door.is_empty():
		toggle_door(door)
		return
	var world := view_transform().affine_inverse() * local_position
	if not exterior and object_bounds("cockpit",2).has_point(world):
		if selected_room != "cockpit":
			room_selected.emit("cockpit")
		selected_object = 2
		object_selected.emit("cockpit",2)
		toggle_seat()
		return
	var object_index := object_at(local_position)
	if object_index >= 0:
		selected_object = object_index
		object_selected.emit(selected_room,object_index)
		return
	var id := room_at(local_position)
	if not id.is_empty():
		room_selected.emit(id)

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
	if manual_hold <= 0 and autonomous_activity in ["maintenance","field_repair"]:
		return "working"
	if manual_hold <= 0 and autonomous_activity == "sleeping":
		return "sleeping"
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
	var sky := Rect2(Vector2(-70,-45),Vector2(240*size.x/maxf(size.y,1),240))
	var sky_scale := size.y/240.0
	draw_set_transform(-sky.position*sky_scale,0,Vector2.ONE*sky_scale)
	backdrop.draw_world(self,Game.state.cruise_seconds,sky)
	draw_set_transform_matrix(camera_transform())
	draw_asteroids()
	draw_set_transform_matrix(view_transform())
	for item in Game.expansion_catalog:
		if item.id in Game.state.expansions or item.id == preview_expansion:
			expansion_art.draw(self,item,item.id not in Game.state.expansions)
	if exterior:
		draw_exterior()
	else:
		draw_interior()
	for item in Game.expansion_catalog:
		if item.id in Game.state.expansions or item.id == preview_expansion:
			expansion_art.draw_connection(self,item)
	# Engine nozzles are included in the calibrated raster artwork.
	components.draw(self, equipment(), not exterior, true)
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
	pixel_ship_art.draw(self, Game.state.owned, true, equipment(), clock,Game.state.engine_condition,Game.state.calm_lights,Game.state.hull_integrity)
func draw_interior() -> void:
	pixel_ship_art.draw(self, Game.state.owned, false, equipment(), clock,Game.state.engine_condition,Game.state.calm_lights,Game.state.hull_integrity)
	interior_art.draw_doors(self, door_progress)
	draw_interior_selection()
	if robot_seated:
		robot_art.draw(self,seated_origin(),clock,expression(),false,equipment(),true)
	else:
		robot_art.draw(self,robot_position,clock,expression(),robot_walking,equipment())

func fitted_camera() -> Rect2:
	if "habitat" in Game.state.expansions or preview_expansion == "habitat":
		return Rect2(-70,-60,420,460)
	if not Game.state.expansions.is_empty() or not preview_expansion.is_empty():
		return Rect2(-70,-50,420,360)
	return Rect2(-70,-45,420,240)

func sync_layout() -> void:
	var key := str(Game.state.expansions)
	if key == layout_key:
		return
	layout_key = key
	rooms = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms.json"))
	for item in Game.expansion_catalog:
		if item.id not in Game.state.expansions:
			continue
		var b: Array = item.bounds
		rooms[item.id] = {"name":item.name,"bounds":b,"damaged":item.description,"restored":item.description,"objects":["Research station","Equipment rack","Observation port"],"damaged_objects":["Station ready.","Supplies secured.","A quiet view of space."],"restored_objects":["Station ready.","Supplies secured.","A quiet view of space."],"object_bounds":[[b[0]+5,b[1]+24,24,20],[b[0]+32,b[1]+15,20,24],[b[0]+57,b[1]+20,20,25]]}
	if not selected_room.is_empty() and not rooms.has(selected_room):
		selected_room = ""
	reset_zoom()

func set_robot_route(destination: Vector2) -> void:
	robot_route.clear()
	if robot_position.y > 110 and destination.y <= 110:
		robot_route.append(Vector2(130,robot_position.y))
		robot_route.append(Vector2(130,103))
	elif destination.y > 110:
		robot_route.append(Vector2(130,robot_position.y))
		if not is_equal_approx(robot_position.y,destination.y):
			robot_route.append(Vector2(130,destination.y))
	robot_route.append(destination)
	robot_destination = robot_route.pop_front()

func advance_autonomy(delta: float) -> void:
	if workshop_mode: return
	manual_hold = maxf(0,manual_hold-delta)
	if manual_hold > 0 or robot_seated: return
	activity_clock += delta
	var next: String = Game.robot_activity()
	if next == autonomous_activity and activity_clock < 40: return
	activity_clock = 0
	autonomous_activity = next
	var destination := Vector2(143,103)
	if next in ["maintenance","field_repair"]: destination = Vector2(205,103)
	if next == "observing": destination = Vector2(80,103)
	seat_requested = false
	set_robot_route(destination)

func draw_asteroids() -> void:
	for event in Game.asteroid_events:
		var age: float = event.age
		var x := -170+age*60
		var y: float = event.lane
		if event.impact and age > 5:
			y += (age-5)*25
		var radius: float = event.radius
		var points := PackedVector2Array()
		for i in range(7):
			points.append(Vector2(x,y)+Vector2.from_angle(i*TAU/7)*(radius*(0.8+0.2*sin(i*3.1))))
		draw_colored_polygon(points,Color("52616c"))
		points.append(points[0])
		draw_polyline(points,Color("82919b"),0.5)

