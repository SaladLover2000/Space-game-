extends Control
const RobotArt = preload("res://assets/robot_art.gd")
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
	var scale_factor := minf((size.x-12)/reference.size.x,(size.y-12)/reference.size.y)
	var offset := (size-reference.size*scale_factor)/2-reference.position*scale_factor
	draw_set_transform(offset,0,Vector2.ONE*scale_factor)
	draw_rect(Rect2(-16,1,32,1),Color("294d60"))
	art.draw(self,Vector2.ZERO,time,mood,false,outfit)
