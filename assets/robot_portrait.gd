extends Control
const RobotArt = preload("res://assets/robot_art.gd")
var art := RobotArt.new()
var subject: Control

func _ready() -> void:
	custom_minimum_size = Vector2(280, 300)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("102337"))
	for x in range(0, int(size.x), 20):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("182e42"))
	for y in range(0, int(size.y), 20):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("182e42"))
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), Color("426b7c"), false, 2)
	var scale_factor := floorf(minf(size.x / 40.0, size.y / 46.0))
	draw_set_transform(Vector2(size.x * 0.5, size.y - 20), 0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(-12, 2, 24, 2), Color("294d60"))
	if is_instance_valid(subject):
		art.draw(self, Vector2.ZERO, subject.clock, subject.expression())
