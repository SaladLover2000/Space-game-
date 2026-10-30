extends Control
var art := preload("res://assets/robot_art.gd").new()
var cabin := preload("res://assets/pixel_ship_art.gd").new()
var actor_present: bool = true
var mode: String = "charging"
var clock: float = 0
var thought: PanelContainer
func _ready() -> void:
	custom_minimum_size = Vector2(620,480)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	thought = preload("res://ui/robot_thought.gd").new()
	thought.room = "charging"
	add_child(thought)
func _process(delta: float) -> void:
	clock += delta
	thought.room = "charging" if mode == "charging" else "quarters"
	thought.follow(size*Vector2(0.48,0.20),size,clock)
	thought.visible = thought.visible and actor_present and mode != "charging"
	queue_redraw()
func charging_mood() -> String:
	if mode != "charging": return "inspecting" if fposmod(clock,12) < 5 else "working"
	return "charging" if Game.state.battery < 100 else "idle"
func _draw() -> void:
	var region := Rect2(590,420,355,220)
	var room_texture := cabin.quarters_texture(Game.state.owned)
	draw_texture_rect(room_texture,Rect2(Vector2.ZERO,size),false)
	# Same cradle and room registration as the cutaway, rather than workshop scenery.
	var scale := size/Vector2(77,49)
	draw_set_transform(Vector2.ZERO,0,scale)
	cabin.service.draw_cabin(self,"dock",Rect2(0,0,35,46))
	cabin.service.draw_cabin(self,"bench",Rect2(36,0,34,46))
	cabin.draw_decor(self,Rect2(0,0,77,49))
	if "quarters" not in Game.state.owned: cabin.service.draw(self,"spares",Rect2(63,42,13,6))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if actor_present:
		var actor := actor_state()
		draw_set_transform(actor.feet,0,Vector2.ONE*actor.scale)
		art.draw(self,Vector2.ZERO,clock,charging_mood(),false,Game.state.equipped,false,0 if mode == "charging" else 3)

func actor_state() -> Dictionary:
	var floor_fraction := 0.77 if mode == "charging" else 0.89
	var scale_factor := minf(size.x/77.0,size.y/49.0)*0.70
	return {"feet":size*Vector2(18.0/77.0 if mode == "charging" else 58.0/77.0,floor_fraction),"scale":scale_factor}
