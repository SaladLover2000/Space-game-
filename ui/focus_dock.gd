extends PanelContainer
signal cancel_requested
var timer: Label
var reward: Label
var start_button: Button
var pause_button: Button
var duration: SpinBox
var presets: HBoxContainer
var task: LineEdit
var task_save: Timer
var dismissed: bool = false
var context_hidden: bool = false

func text(parent: Node, value: String, size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size",size)
	parent.add_child(node)
	return node

func action(parent: Node, title: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = title
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	add_child(row)
	var clock_column := VBoxContainer.new()
	row.add_child(clock_column)
	text(clock_column,"FOCUS",12).modulate = Color("9bb9c7")
	timer = text(clock_column,"25:00",44)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation",5)
	row.add_child(center)
	task = LineEdit.new()
	task.placeholder_text = "Write what you are working on to begin"
	task.text = Game.state.focus_task
	center.add_child(task)
	var options := HBoxContainer.new()
	center.add_child(options)
	duration = SpinBox.new()
	duration.min_value = 1
	duration.max_value = 240
	duration.value = 25
	duration.suffix = " min"
	options.add_child(duration)
	presets = HBoxContainer.new()
	options.add_child(presets)
	for minutes in [25,45,60]:
		var value: int = minutes
		action(presets,str(minutes),func(): duration.value = value)
	reward = text(options,"",12)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var controls := VBoxContainer.new()
	row.add_child(controls)
	start_button = action(controls,"Start focus",func(): flush_task(); Game.start_session(int(duration.value)))
	pause_button = action(controls,"Pause",func(): Game.toggle_pause())
	var secondary := HBoxContainer.new()
	controls.add_child(secondary)
	action(secondary,"Cancel",func(): cancel_requested.emit())
	action(secondary,"Hide",func(): dismissed = true; hide())
	task_save = Timer.new()
	task_save.one_shot = true
	task_save.wait_time = 0.5
	add_child(task_save)
	task_save.timeout.connect(flush_task)
	task.text_changed.connect(func(_value): task_save.start(); refresh())
	task.text_submitted.connect(func(_value): flush_task())
	task.focus_exited.connect(flush_task)
	duration.value_changed.connect(func(_value): refresh())
	Game.changed.connect(refresh)
	refresh()

func flush_task() -> void:
	if not is_instance_valid(task) or task.text == Game.state.focus_task: return
	Game.state.focus_task = task.text.strip_edges().left(160)
	Game.save_progress()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(timer): return
	visible = Game.state.started and not dismissed and not context_hidden
	var active: bool = not Game.active.is_empty()
	var minutes: int = int(Game.active.minutes) if active else int(duration.value)
	var seconds: int = ceili(float(Game.active.remaining_ms)/1000.0) if active else minutes*60
	timer.text = "%02d:%02d" % [seconds/60,seconds%60]
	var title_ready := not task.text.strip_edges().is_empty()
	reward.text = "Paused" if active and Game.active.paused else "Focusing" if active else "Ready" if title_ready else "Add a task to start"
	reward.text += " / +%d credits, +%d XP" % [minutes*int(Game.balance.credits_per_minute),minutes*int(Game.balance.xp_per_minute)]
	start_button.visible = not active
	start_button.disabled = active or not title_ready
	pause_button.visible = active
	pause_button.disabled = not active or (active and Game.active.paused and Game.active.get("task","").strip_edges().is_empty() and not title_ready)
	pause_button.text = "Resume" if active and Game.active.paused else "Pause"
	duration.editable = not active
	for button in presets.get_children(): button.disabled = active

func reveal() -> void:
	dismissed = false
	refresh()
