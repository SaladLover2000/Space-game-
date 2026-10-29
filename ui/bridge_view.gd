extends Control
const BACKPLATE = preload("res://assets/art/immersive-cockpit-v1.png")
const DAMAGED = preload("res://assets/art/immersive-cockpit-damaged-v2.png")
const RobotArt = preload("res://assets/robot_art.gd")
var space := preload("res://assets/space_backdrop.gd").new()
var art := RobotArt.new()
var clock: float = 0.0
var mode: String = "navigation"
var actor_present: bool = true
var thought: PanelContainer

func _ready() -> void:
	thought = preload("res://ui/robot_thought.gd").new()
	thought.room = "cockpit"
	add_child(thought)
	custom_minimum_size = Vector2(620,500)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	if thought != null:
		thought.follow(actor_state().feet-Vector2(0,size.y*0.48),size,clock)
		thought.visible = thought.visible and actor_present
	queue_redraw()

func set_mode(value: String) -> void:
	if value in ["diagnostics","navigation","rest"]:
		mode = value

func work_state() -> String:
	if not actor_present: return "The robot is waiting at a closed hatch. Open connecting hatches to let him enter."
	if mode == "rest": return "Taking a quiet moment at the window."
	if mode == "navigation":
		return "Navigation rebuild installed. Plotting a safe course." if "navigation_patch" in Game.state.research else "Legacy navigation: tracing faults and preparing a software rebuild."
	return art.work_action(clock).description + ": checking circuits and testing the console."

func _draw() -> void:
	draw_texture_rect(background_texture(),Rect2(Vector2.ZERO,size),false)
	draw_window_space()
	var screen := Rect2(size*Vector2(0.435,0.515),size*Vector2(0.14,0.075))
	var online: bool = "navigation_patch" in Game.state.research
	draw_rect(screen,Color("07131c"))
	var caption: String = "DRIFTING / NAV OFFLINE" if not online else "COURSE HOLD / "+Game.state.flight_mode.to_upper()
	draw_string(ThemeDB.fallback_font,screen.position+Vector2(3,screen.size.y*0.30),caption,HORIZONTAL_ALIGNMENT_LEFT,screen.size.x-6,maxi(7,int(size.y/65)),Color("ea7968" if not online else "78cabc"))
	for i in range(4):
		var width := screen.size.x*(0.2+fposmod(i*0.17+floorf(clock*2)*0.03,0.70))
		draw_rect(Rect2(screen.position+Vector2(3,screen.size.y*(0.45+i*0.12)),Vector2(width,1)),Color("b18165" if not online else "78b7ab"))
	if not actor_present: return
	var actor := actor_state()
	draw_set_transform(actor.feet,0,Vector2.ONE*actor.scale)
	art.draw(self,Vector2.ZERO,clock,actor.mood,false,Game.state.equipped,actor.seated,actor.angle)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if actor.seated:
		# The chair back is in front of the seated body; hands remain above its rim.
		var chair := Rect2(size*Vector2(0.277,0.65),size*Vector2(0.245,0.29))
		draw_texture_rect_region(background_texture(),chair,Rect2(Vector2(background_texture().get_size())*Vector2(0.277,0.65),Vector2(background_texture().get_size())*Vector2(0.245,0.29)))

func background_texture() -> Texture2D:
	return BACKPLATE if "cockpit" in Game.state.owned else DAMAGED

func actor_state() -> Dictionary:
	var seated := mode in ["navigation","rest"]
	return {"feet":Vector2(size.x*(0.405 if seated else 0.70),size.y*0.96),"scale":size.y/60.0,"seated":seated,"angle":2 if seated else 1,"mood":"idle" if mode == "rest" else "typing" if mode == "navigation" else "inspecting"}

func draw_window_space() -> void:
	var corners := PackedVector2Array([size*Vector2(0.10,0.15),size*Vector2(0.88,0.15),size*Vector2(0.92,0.45),size*Vector2(0.08,0.45)])
	var uv := PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	draw_polygon(corners,PackedColorArray([Color.WHITE]),uv,space.nebula)
	for i in range(75):
		var point := size*Vector2(0.08+fposmod(i*0.041+Game.state.cruise_seconds*0.0006,0.84),0.16+fposmod(i*0.061,0.27))
		if Geometry2D.is_point_in_polygon(point,corners): draw_rect(Rect2(point,Vector2.ONE*maxf(1,floorf(size.y/300))),Color("8ba1b4"))
	var phase := fposmod(Game.state.cruise_seconds,180)
	if phase > 50 and phase < 150:
		var radius := size.y*0.095
		var center := size*Vector2(0.20+(phase-50)*0.005,0.30)
		draw_texture_rect(space.planets[int(Game.state.cruise_seconds/180)%3],Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),false)
