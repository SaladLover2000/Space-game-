extends Control
const BACKPLATE = preload("res://assets/art/immersive-cockpit-v1.png")
const DAMAGED = preload("res://assets/art/immersive-cockpit-damaged-v2.png")
const RobotArt = preload("res://assets/robot_art.gd")
var art := RobotArt.new()
var clock: float = 0.0
var mode: String = "diagnostics"

func _ready() -> void:
	custom_minimum_size = Vector2(620,500)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func set_mode(value: String) -> void:
	if value in ["diagnostics","navigation","rest"]:
		mode = value

func work_state() -> String:
	if mode == "rest": return "Taking a quiet moment at the window."
	if mode == "navigation":
		return "Navigation rebuild installed. Plotting a safe course." if "navigation_patch" in Game.state.research else "Legacy navigation: tracing faults and preparing a software rebuild."
	return art.work_action(clock).description + ": checking circuits and testing the console."

func _draw() -> void:
	draw_texture_rect(background_texture(),Rect2(Vector2.ZERO,size),false)
	# This live star drift is separate from the cockpit furnishings.
	for i in range(25):
		var x := size.x*(0.15+fposmod(i*0.041-clock*0.004,0.7))
		var y := size.y*(0.16+fposmod(i*0.061,0.25))
		draw_rect(Rect2(x,y,1,1),Color(0.8,0.95,1,0.6))
	var screen := Rect2(size*Vector2(0.42,0.54),size*Vector2(0.13,0.04))
	for i in range(5):
		var width := screen.size.x*(0.2+fposmod(i*0.17,0.75))
		draw_rect(Rect2(screen.position+Vector2(0,i*screen.size.y/5),Vector2(width,1)),Color("78dfca"))
	var actor := actor_state()
	draw_set_transform(actor.feet,0,Vector2.ONE*actor.scale)
	art.draw(self,Vector2.ZERO,clock,actor.mood,false,Game.state.equipped,actor.seated,actor.angle)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func background_texture() -> Texture2D:
	return BACKPLATE if "cockpit" in Game.state.owned else DAMAGED

func actor_state() -> Dictionary:
	var seated := mode in ["navigation","rest"]
	return {"feet":Vector2(size.x*(0.405 if seated else 0.70),size.y*0.96),"scale":size.y/(60.0 if seated else 54.0),"seated":seated,"angle":2 if seated else 1,"mood":"idle" if mode == "rest" else "typing" if mode == "navigation" else "working"}

