extends Control
const RobotArt = preload("res://assets/robot_art.gd")
signal service_changed
var service_mode: bool = false
var service_state: String = "free"
var rack_progress: float = 0.0
var install_left: float = 0.0
var art := RobotArt.new()
var subject: Control
var preview_equipped: Dictionary = {}
var preview_mode: bool = false
var clock: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	advance_service(delta)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("102337"))
	for x in range(0, int(size.x), 20):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("182e42"))
	for y in range(0, int(size.y), 20):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("182e42"))
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), Color("426b7c"), false, 2)
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
		mood = "working" if service_state == "installing" else "idle"
	art.draw(self,Vector2(0,-rack_progress*2) if service_mode else Vector2.ZERO,time,mood,false,outfit)

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

func draw_lift(outfit: Dictionary) -> void:
	var bounds := art.bounds(outfit)
	var top := minf(-48,bounds.position.y-6)
	var half := maxf(24,bounds.size.x/2+7)
	for side in [-1,1]:
		var x: float = half*side
		draw_rect(Rect2(x-2,top,4,-top+4),Color("526773"))
		draw_rect(Rect2(x-0.5,top,1,-top+4),Color("a9bec7"))
		for y in range(int(top)+4,0,6): draw_rect(Rect2(x-1,y,2,2),Color("223746"))
		var clamp_x := lerpf(half-2,bounds.size.x/2-1,rack_progress)
		draw_line(Vector2(x,top*0.45),Vector2(side*clamp_x,top*0.45),Color("d3ac61"),2)
		draw_rect(Rect2(side*clamp_x-1,top*0.45-3,2,6),Color("97b9c4"))
	draw_rect(Rect2(-half-3,top-3,half*2+6,4),Color("7e969f"))
	draw_rect(Rect2(-half-3,2-rack_progress*2,half*2+6,4),Color("687e88"))
	for x in range(-int(half),int(half),5): draw_rect(Rect2(x,3-rack_progress*2,2,1),Color("d3ac61"))

