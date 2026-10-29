extends Control
var machinery := preload("res://assets/engine_bay_art.gd").new()
var preview_tiers: Dictionary = {}
var art := preload("res://assets/robot_art.gd").new()
var thought: PanelContainer
var clock: float = 0
var actor_present: bool = true
var actor_x: float = 0.20
var chosen_task: int = -1
var task_left: float = 0
func _ready() -> void:
	custom_minimum_size = Vector2(620,460)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	thought = preload("res://ui/robot_thought.gd").new()
	thought.room = "engine"
	add_child(thought)
func _process(delta: float) -> void:
	clock += delta
	task_left = maxf(0,task_left-delta)
	if task_left == 0: chosen_task = -1
	actor_x = move_toward(actor_x,[0.20,0.43,0.69][task_index()],delta*0.10)
	thought.follow(size*Vector2(0.22,0.45),size,clock)
	thought.visible = thought.visible and actor_present
	queue_redraw()
func background_texture() -> Texture2D:
	return preload("res://assets/art/engine-bay-mounts-v1.png")
func _draw() -> void:
	draw_texture_rect(background_texture(),Rect2(Vector2.ZERO,size),false)
	machinery.draw(self,size,Game.state.engine_modules,Game.state.engine_condition,"engine" in Game.state.owned,preview_tiers)
	if Game.state.engine_condition < 75:
		for i in range(4):
			var age := fposmod(clock*0.9+i*0.23,1)
			if age < 0.24:
				var spark := size*Vector2(0.38,0.50)+Vector2(10+i*7,age*50)
				draw_line(spark,spark+Vector2(2,4),Color("e8ad58"),1)
	if not actor_present: return
	var task := task_index()
	var feet := size*Vector2(actor_x,0.96)
	var mood := "inspecting" if fposmod(clock,12) < 6 else "working"
	draw_set_transform(feet,0,Vector2.ONE*size.y/80)
	art.draw(self,Vector2.ZERO,clock,mood,absf(actor_x-[0.20,0.43,0.69][task]) > 0.01,Game.state.equipped,false,3 if task == 0 else 1)

func task_index() -> int:
	return chosen_task if chosen_task >= 0 else int(clock/16)%3
func choose_task(index: int) -> void:
	chosen_task = clampi(index,0,2)
	task_left = 30
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		choose_task(0 if event.position.x < size.x*0.28 else 1 if event.position.x < size.x*0.60 else 2)
		accept_event()
