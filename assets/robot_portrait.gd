extends Control
const RobotArt = preload("res://assets/robot_art.gd")
signal service_changed
var service_mode: bool = false
var service_state: String = "free"
var rack_progress: float = 0.0
var install_left: float = 0.0
var view_angle: int = 0
var turn_dragging: bool = false
var drag_origin: float = 0
var maintenance := preload("res://assets/maintenance_art.gd").new()
var service_art := preload("res://assets/service_art.gd").new()
var art := RobotArt.new()
var subject: Control
var preview_equipped: Dictionary = {}
var preview_mode: bool = false
var clock: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 300)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	advance_service(delta)
	queue_redraw()

func _draw() -> void:
	if service_mode:
		draw_texture_rect(preload("res://assets/art/robot-workshop-v1.png"),Rect2(Vector2.ZERO,size),false)
	else: draw_rect(Rect2(Vector2.ZERO,size),Color("101923"))
	if service_mode: service_art.draw(self,"spares",Rect2(size*Vector2(0.76,0.78),size*Vector2(0.19,0.19)))
	var outfit: Dictionary = Game.state.equipped
	var mood: String = "idle"
	var time: float = clock
	if preview_mode and not preview_equipped.is_empty():
		outfit = preview_equipped
	if is_instance_valid(subject):
		mood = subject.expression()
		time = subject.clock
	# A shared scale shows real size differences rather than enlarging every build equally.
	var reference := Rect2(-28,-50,56,54).merge(art.bounds(outfit,time,mood).grow(2))
	if service_mode: reference = reference.merge(Rect2(-34,-65,68,74))
	var scale_factor := minf((size.x-12)/reference.size.x,(size.y-12)/reference.size.y)
	var offset := (size-reference.size*scale_factor)/2-reference.position*scale_factor
	draw_set_transform(offset,0,Vector2.ONE*scale_factor)
	draw_rect(Rect2(-16,1,32,1),Color("294d60"))
	if service_mode:
		draw_lift(outfit)
		mood = "idle"
	art.draw(self,Vector2(0,-maintenance.hoist_lift(rack_progress)) if service_mode else Vector2.ZERO,time,mood,false,outfit,false,view_angle)

func service_ready() -> bool:
	return service_mode and service_state == "racked"

func request_rack() -> void:
	if service_state == "free":
		service_state = "racking"
		service_changed.emit()

func request_release() -> void:
	if service_state in ["racked","racking"]:
		service_state = "releasing"
		service_changed.emit()

func begin_install() -> void:
	service_state = "installing"
	install_left = 0.8
	service_changed.emit()

func advance_service(delta: float) -> void:
	if service_state == "racking":
		rack_progress = move_toward(rack_progress,1,delta/1.2)
		if rack_progress == 1:
			service_state = "racked"
			service_changed.emit()
	elif service_state == "releasing":
		rack_progress = move_toward(rack_progress,0,delta/0.8)
		if rack_progress == 0:
			service_state = "free"
			service_changed.emit()
	elif service_state == "installing":
		install_left = maxf(0,install_left-delta)
		if install_left == 0:
			service_state = "racked"
			service_changed.emit()

func lift_layout(outfit: Dictionary) -> Array:
	var bounds := art.bounds(outfit)
	var top := minf(-53,bounds.position.y-14)
	var lift: float = maintenance.hoist_lift(rack_progress)
	var shoulder := bounds.position.y+art.part_size(art.resolve("robot_visor",outfit)).y+2-lift
	var width := art.part_size(art.resolve("robot_shell",outfit)).x+10
	var pieces := [{"id":"winch","rect":Rect2(-17,top-5,34,12)}]
	for side in [-1,1]:
		var x: float = side*width*0.43
		pieces.append({"id":"chain","rect":Rect2(x-0.8,top+5,1.6,maxf(3,shoulder-top-5))})
	pieces.append({"id":"spreader","rect":Rect2(-width/2,shoulder-3,width,14)})
	return pieces

func draw_lift(outfit: Dictionary) -> void:
	for piece in lift_layout(outfit): maintenance.draw(self,piece.id,piece.rect)

func _gui_input(event: InputEvent) -> void:
	if not service_mode: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		turn_dragging = event.pressed
		drag_origin = event.position.x
		accept_event()
	elif event is InputEventMouseMotion and turn_dragging and absf(event.position.x-drag_origin) >= 50:
		view_angle = posmod(view_angle+(1 if event.position.x > drag_origin else -1),4)
		drag_origin = event.position.x
		queue_redraw()
		accept_event()
