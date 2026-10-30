extends Control
signal service_note(message: String)
var machinery := preload("res://assets/engine_bay_art.gd").new()
var props := preload("res://assets/pixel_props.gd").new()
var preview_tiers: Dictionary = {}
var art := preload("res://assets/robot_art.gd").new()
var thought: PanelContainer
var clock: float = 0
var actor_present: bool = true
var actor_x: float = 0.20
var chosen_task: int = -1
var task_left: float = 0
var work_clock: float = 0
var last_work_task: int = -1
var sorted_count: int = 0
var assembly_mode: bool = false
var assembly_slots: Dictionary = {}
var selected_assembly: String = ""
var drag_position := Vector2.ZERO
var assembly_dragging: bool = false
const WORK_X = [0.20,0.43,0.69]
const PART_COUNT = 6

func _ready() -> void:
	custom_minimum_size = Vector2(620,460)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	thought = preload("res://ui/robot_thought.gd").new()
	thought.room = "engine"
	add_child(thought)

func _process(delta: float) -> void:
	clock += delta
	var task := task_index()
	if task != last_work_task:
		work_clock = 0
		last_work_task = task
	actor_x = move_toward(actor_x,WORK_X[task],delta*0.10)
	if actor_present and not assembly_mode and not is_walking():
		work_clock += delta
		if task == 2: sorted_count = mini(PART_COUNT,int(work_clock/3.0))
		task_left = maxf(0,task_left-delta)
		if task_left == 0: chosen_task = -1
	thought.follow(size*Vector2(actor_x,0.40),size,clock)
	thought.visible = thought.visible and actor_present and not assembly_mode
	if thought.words != null:
		thought.words.text = "Walking to the work station." if is_walking() else ["Tracing the control-panel circuit.","Torque-checking the pump seal.","Sorting parts into rack bins / %d of %d" % [sorted_count,PART_COUNT]][task]
	queue_redraw()

func background_texture() -> Texture2D:
	return preload("res://assets/art/engine-bay-clear-deck-v2.png")

func is_walking() -> bool:
	return absf(actor_x-WORK_X[task_index()]) > 0.005

func actor_state() -> Dictionary:
	var task := task_index()
	var walking := is_walking()
	var mood := "idle" if walking else "inspecting" if task == 0 else "sealing" if task == 1 else "sorting"
	var phase := fposmod(work_clock,3.0)
	var right := Vector2(12,-22)
	if task == 1: right = Vector2(2.5+sin(work_clock*3)*0.5,-27)
	if task == 2:
		var pickup := Vector2(9,-12)
		var deposit := Vector2(14,-15)
		right = pickup.lerp(deposit,smoothstep(0.8,2.0,phase)) if phase < 2.2 else deposit.lerp(pickup,(phase-2.2)/0.8)
	return {"feet":size*Vector2(actor_x,0.93),"scale":size.y/80.0,"walking":walking,"mood":mood,"angle":1 if task == 2 else 3,"targets":{} if walking else {"right":right,"left":Vector2(-3,-19),"hide_tool":task != 1}}

func _draw() -> void:
	draw_texture_rect(background_texture(),Rect2(Vector2.ZERO,size),false)
	var visible: Array = assembly_slots.keys() if assembly_mode else machinery.IDS
	machinery.draw(self,size,Game.state.engine_modules,Game.state.engine_condition,"engine" in Game.state.owned,preview_tiers,visible)
	if assembly_mode:
		draw_assembly()
		return
	draw_sorting_station()
	if not actor_present: return
	var actor := actor_state()
	draw_set_transform(actor.feet,0,Vector2.ONE*actor.scale)
	art.draw(self,Vector2.ZERO,clock if actor.walking else work_clock,actor.mood,actor.walking,Game.state.equipped,false,actor.angle,actor.targets)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	var sorting := sorting_state()
	if sorting.held >= 0:
		var hand: Vector2 = art.tool_position(Game.state.equipped,work_clock,actor.angle,false,actor.mood,actor.targets)
		if actor.angle == 3: hand.x = -hand.x
		props.draw_part(self,sorting.held,actor.feet+hand*actor.scale,maxf(1,size.y/260))
	if task_index() == 1 and not actor.walking:
		var anchor: Vector2 = art.tool_position(Game.state.equipped,0,3,false,"sealing",{"right":Vector2(2.5,-27),"left":Vector2(-3,-19)})
		anchor.x = -anchor.x
		var seal: Vector2 = actor.feet+(anchor+Vector2(0,-5.5))*actor.scale
		draw_rect(Rect2(seal-Vector2(3,5),Vector2(6,10)),Color("b98b48"),false,1)

func task_index() -> int:
	return chosen_task if chosen_task >= 0 else int(clock/16)%3

func choose_task(index: int) -> void:
	assembly_mode = false
	chosen_task = clampi(index,0,2)
	task_left = 30
	work_clock = 0
	if index == 2: sorted_count = 0
	service_note.emit(["Walking to the panel to inspect its controls.","Walking to the pump coupling to check its seal.","Moving loose parts from the tray into the labeled rack."][chosen_task])

func sorting_state() -> Dictionary:
	var held := sorted_count if task_index() == 2 and actor_present and not is_walking() and sorted_count < PART_COUNT and fposmod(work_clock,3) >= 0.8 and fposmod(work_clock,3) < 2.2 else -1
	var pieces: Array = []
	for i in range(PART_COUNT):
		if i == held: continue
		var placed := i < sorted_count
		var point := size*Vector2(0.80+(i%3)*0.052,0.70+(i/3)*0.043) if placed else size*Vector2(0.745+(i%3)*0.030,0.80+(i/3)*0.030)
		pieces.append({"id":i,"position":point,"sorted":placed})
	return {"held":held,"pieces":pieces,"count":sorted_count}

func draw_sorting_station() -> void:
	var rack := Rect2(size*Vector2(0.79,0.65),size*Vector2(0.19,0.13))
	draw_rect(rack,Color("142331"))
	for piece in props.rack_geometry(rack): draw_rect(piece.rect,Color(piece.color))
	var tray := Rect2(size*Vector2(0.73,0.79),size*Vector2(0.12,0.07))
	draw_rect(tray.grow(3),Color("172330"))
	draw_rect(Rect2(tray.position,tray.size*Vector2(1,0.16)),Color("bb9559"))
	for x in [0.735,0.84]:
		draw_rect(Rect2(size*Vector2(x,0.85),size*Vector2(0.008,0.10)),Color("64717b"))
	for piece in sorting_state().pieces: props.draw_part(self,piece.id,piece.position,maxf(1,size.y/260))

func begin_assembly(upgraded_id: String = "") -> bool:
	if "engine" not in Game.state.owned:
		service_note.emit("Restore the engine before assembling its hardware.")
		return false
	assembly_mode = true
	assembly_slots.clear()
	if not upgraded_id.is_empty():
		for id in machinery.IDS:
			if id != upgraded_id: assembly_slots[id] = true
	selected_assembly = upgraded_id
	assembly_dragging = false
	preview_tiers.clear()
	service_note.emit("Select a part from the tray, then its matching socket. You can also drag it into place.")
	queue_redraw()
	return true

func assembly_complete() -> bool:
	return assembly_slots.size() == machinery.IDS.size()

func assembly_tray() -> Array:
	var result: Array = []
	for index in range(machinery.IDS.size()):
		var id: String = machinery.IDS[index]
		if not assembly_slots.has(id): result.append({"id":id,"rect":Rect2(size*Vector2(0.05+index*0.24,0.79),size*Vector2(0.19,0.16))})
	return result

func assembly_socket(id: String) -> Rect2:
	for piece in machinery.layout(Game.state.engine_modules,Game.state.engine_condition,true):
		if piece.id == id: return Rect2(piece.rect.position*size,piece.rect.size*size)
	return Rect2()

func place_assembly(id: String, point: Vector2) -> bool:
	if not assembly_mode or id not in machinery.IDS or assembly_slots.has(id) or not assembly_socket(id).has_point(point): return false
	assembly_slots[id] = true
	selected_assembly = ""
	service_note.emit("Engine assembled: pump, injector, cooling and nozzle connected." if assembly_complete() else id.capitalize()+" secured. Fit the next assembly.")
	queue_redraw()
	return true

func draw_assembly() -> void:
	for id in machinery.IDS:
		var socket := assembly_socket(id)
		if not assembly_slots.has(id):
			draw_rect(socket,Color("142331"),false,2)
			draw_string(ThemeDB.fallback_font,socket.position+Vector2(4,16),id.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,socket.size.x-8,12,Color("dcc99b"))
	for part in assembly_tray():
		draw_rect(part.rect,Color("152535"))
		draw_rect(part.rect,Color("bc965d" if part.id == selected_assembly else "52616e"),false,2)
		draw_texture_rect_region(machinery.ATLAS,part.rect.grow(-6),machinery.source(part.id,mini(3,int(Game.state.engine_modules[part.id])+1)))
	if assembly_dragging and not selected_assembly.is_empty():
		draw_texture_rect_region(machinery.ATLAS,Rect2(drag_position-size*Vector2(0.07,0.07),size*Vector2(0.14,0.14)),machinery.source(selected_assembly,mini(3,int(Game.state.engine_modules[selected_assembly])+1)))

func _gui_input(event: InputEvent) -> void:
	if assembly_mode:
		if event is InputEventMouseMotion and assembly_dragging:
			drag_position = event.position
			queue_redraw()
			accept_event()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				for part in assembly_tray():
					if part.rect.has_point(event.position):
						selected_assembly = part.id
						assembly_dragging = true
						drag_position = event.position
						accept_event()
						return
			elif not selected_assembly.is_empty():
				place_assembly(selected_assembly,event.position)
				assembly_dragging = false
			queue_redraw()
			accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		choose_task(0 if event.position.x < size.x*0.28 else 1 if event.position.x < size.x*0.60 else 2)
		accept_event()
