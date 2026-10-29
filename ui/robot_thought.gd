extends PanelContainer
var room: String = "ship"
var words: Label
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15212ce8")
	style.border_color = Color("9ca5a3")
	style.set_border_width_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel",style)
	words = Label.new()
	words.custom_minimum_size.x = 190
	words.max_lines_visible = 3
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_theme_font_size_override("font_size",13)
	add_child(words)
func follow(point: Vector2, area: Vector2, clock: float) -> void:
	if words == null: return
	words.text = Game.robot_thought(room,clock)
	visible = fposmod(clock,14) < 6
	position = Vector2(clampf(point.x+12,4,maxf(4,area.x-230)),clampf(point.y-70,4,maxf(4,area.y-90)))
