extends Control

const ShipView = preload("res://assets/ship_view.gd")
const RobotPortrait = preload("res://assets/robot_portrait.gd")
const Workshop = preload("res://ui/workshop.gd")
var workshop: Control
var root: VBoxContainer
var content: VBoxContainer
var timer_label: Label
var reward_label: Label
var status: Label
var message: Label
var pause_button: Button
var start_button: Button
var duration: SpinBox
var presets: HBoxContainer
var current_page := "menu"
var notice := ""
var compact_window: Window
var compact_label: Label
var sound_player: AudioStreamPlayer
var ship_view: Control
var room_panel: VBoxContainer
var selected_room: String = ""
var robot_mood: Label
var drift_status: Label
var inspection_label: Label
var name_autosave: Timer
var robot_name_edit: LineEdit
var ship_name_edit: LineEdit
var name_save_button: Button
var name_hint: Label
var names_dirty: bool = false

func _ready() -> void:
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 17
	for kind in ["Button", "LineEdit", "SpinBox", "PanelContainer"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("18283f")
		style.border_color = Color("38536c")
		style.set_border_width_all(2)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme_resource.set_stylebox("normal" if kind != "PanelContainer" else "panel", kind, style)
		var hover := style.duplicate()
		hover.bg_color = Color("25445b")
		theme_resource.set_stylebox("hover", kind, hover)
	theme = theme_resource
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var title := label("L I T T L E   O R B I T", 28)
	title.modulate = Color("7de1d6")
	root.add_child(title)
	status = label("", 15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status)
	var nav := HBoxContainer.new()
	root.add_child(nav)
	for entry in [["Home", "menu"], ["Ship & study", "ship"], ["Interior", "interior"], ["Drift", "drift"], ["Robot", "robot"], ["Shop", "shop"], ["Study log", "stats"], ["Settings", "settings"]]:
		var target: String = entry[1]
		button(nav, entry[0], func(): show_page(target))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	message = label("", 15)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.modulate = Color("e8cf87")
	root.add_child(message)
	Game.changed.connect(refresh)
	Game.completed.connect(on_completed)
	Game.storage_error.connect(func(text: String): notice = text; refresh())
	Game.storage_recovered.connect(func(previous: String):
		if notice == previous:
			notice = ""
			refresh())
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	name_autosave = Timer.new()
	name_autosave.one_shot = true
	name_autosave.wait_time = 0.45
	name_autosave.timeout.connect(flush_name_edits)
	add_child(name_autosave)
	notice = Game.last_error
	show_page("menu")
	get_tree().auto_accept_quit = false

func label(text: String, font_size: int = 18) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	return result

func paragraph(text: String) -> void:
	var result := label(text)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(result)

func button(parent: Node, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.pressed.connect(action)
	parent.add_child(result)
	return result

func show_page(page: String) -> void:
	flush_name_edits()
	if not Game.state.started and page != "menu":
		page = "setup"
	current_page = page
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	timer_label = null
	reward_label = null
	start_button = null
	pause_button = null
	duration = null
	ship_view = null
	room_panel = null
	robot_mood = null
	drift_status = null
	inspection_label = null
	workshop = null
	robot_name_edit = null
	ship_name_edit = null
	name_save_button = null
	name_hint = null
	match page:
		"menu":
			content.add_child(ShipView.new())
			paragraph("A quiet corner of the universe. A small companion. One session at a time.")
			button(content, "Continue your journey" if Game.state.started else "Begin your journey", func(): show_page("ship" if Game.state.started else "setup"))
			paragraph("Your progress stays with you. Missing a day never hurts your robot.")
		"setup":
			names_form(true)
		"interior":
			paragraph("INSIDE / " + Game.state.ship)
			build_ship_explorer()
			ship_view.custom_minimum_size.y = 360
			drift_status = label("")
			content.add_child(drift_status)
			button(content, "Study controls", func(): show_page("ship"))
		"drift":
			paragraph("OUTSIDE / " + Game.state.ship)
			ship_view = ShipView.new()
			ship_view.exterior = true
			content.add_child(ship_view)
			ship_view.custom_minimum_size.y = 360
			drift_status = label("")
			content.add_child(drift_status)
			paragraph("A little home passing quietly through a colorful universe.")
			button(content, "Return to ship & study", func(): show_page("ship"))
		"ship":
			var row := HBoxContainer.new()
			content.add_child(row)
			duration = SpinBox.new()
			duration.min_value = 1
			duration.max_value = 240
			duration.value = 25
			duration.suffix = " min"
			row.add_child(duration)
			presets = HBoxContainer.new()
			row.add_child(presets)
			for minutes in [25, 45, 60, 90, 120]:
				var value: int = minutes
				button(presets, str(minutes), func(): duration.value = value)
			timer_label = label("", 36)
			content.add_child(timer_label)
			reward_label = label("", 17)
			reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(reward_label)
			var controls := HBoxContainer.new()
			content.add_child(controls)
			start_button = button(controls, "Start study", func(): Game.start_session(int(duration.value)))
			pause_button = button(controls, "Pause", func(): Game.toggle_pause())
			button(controls, "Cancel session", confirm_cancel)
			button(controls, "Compact timer", open_compact)
			build_ship_explorer()
		"shop":
			workshop = Workshop.new()
			content.add_child(workshop)
		"robot":
			var companion_row := HBoxContainer.new()
			companion_row.add_theme_constant_override("separation", 12)
			content.add_child(companion_row)
			ship_view = ShipView.new()
			var portrait := RobotPortrait.new()
			portrait.subject = ship_view
			companion_row.add_child(portrait)
			companion_row.add_child(ship_view)
			ship_view.custom_minimum_size.x = 500
			ship_view.focus_room("quarters")
			paragraph("YOUR COMPANION / " + Game.state.robot)
			robot_mood = label("")
			content.add_child(robot_mood)
			var battery := ProgressBar.new()
			battery.value = Game.state.battery
			battery.custom_minimum_size.y = 24
			content.add_child(battery)
			paragraph("Condition / weathered shell, functional study dock. A small companion finding its spark again.")
			paragraph("During a session the dock pulses gently. Battery is awarded on completion; pausing or canceling never drains it.")
			button(content, "Return to ship & study", func(): show_page("ship"))
		"stats":
			paragraph("YOUR STUDY LOG")
			paragraph("%d completed sessions · %d minutes studied" % [Game.state.history.size(), int(Game.state.total_seconds / 60)])
			if Game.state.history.is_empty():
				paragraph("A blank log is a beginning. Your first session can be a small one.")
			for i in range(Game.state.history.size() - 1, -1, -1):
				var entry: Dictionary = Game.state.history[i]
				paragraph("%s  /  %d minutes  /  +%d credits" % [entry.date, entry.minutes, int(entry.get("credits", 0))])
		"settings":
			names_form(false)
			var sound := CheckButton.new()
			sound.text = "Play completion chime"
			sound.button_pressed = Game.state.sound
			sound.toggled.connect(func(enabled: bool): Game.state.sound = enabled; Game.save_progress())
			content.add_child(sound)
			paragraph("Saves are local and automatic. Closing pauses the saved session; reopening never grants time spent away. While running, minimizing keeps the timer counting.")
	refresh()

func names_form(first: bool) -> void:
	paragraph("A LITTLE HOME IN SPACE" if first else "COMPANION & SHIP")
	paragraph("An exhausted robot waits aboard a weathered ship. Give this new beginning a name." if first else "You can change these names whenever you like.")
	robot_name_edit = LineEdit.new()
	robot_name_edit.text = Game.state.robot
	robot_name_edit.max_length = 24
	paragraph("Robot name")
	content.add_child(robot_name_edit)
	ship_name_edit = LineEdit.new()
	ship_name_edit.text = Game.state.ship
	ship_name_edit.max_length = 24
	paragraph("Spaceship name")
	content.add_child(ship_name_edit)
	for field in [robot_name_edit, ship_name_edit]:
		field.text_changed.connect(func(_text: String): queue_name_save())
		field.focus_exited.connect(flush_name_edits)
		field.text_submitted.connect(func(_text: String): submit_names())
	name_hint = label("Names save automatically. Press Enter or use the button to continue.", 15)
	name_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(name_hint)
	name_save_button = button(content, "Make ourselves at home" if first else "Save names", submit_names)

func queue_name_save() -> void:
	names_dirty = true
	name_autosave.start()
	if is_instance_valid(name_hint):
		name_hint.text = "Saving names…"

func flush_name_edits(complete_setup: bool = false) -> bool:
	if not names_dirty and not complete_setup:
		return true
	if not is_instance_valid(robot_name_edit) or not is_instance_valid(ship_name_edit):
		return false
	name_autosave.stop()
	var saved: bool = Game.update_names(robot_name_edit.text, ship_name_edit.text, complete_setup)
	if saved:
		names_dirty = false
	if is_instance_valid(name_hint):
		name_hint.text = "Names saved." if saved else "Could not save. Please try again."
	return saved

func submit_names() -> void:
	if flush_name_edits(true):
		show_page("ship")

func _process(_delta: float) -> void:
	update_timer()
	if is_instance_valid(drift_status):
		drift_status.text = "Study / " + time_text()
	if is_instance_valid(robot_mood) and is_instance_valid(ship_view):
		var descriptions := {"sad": "Resting · low battery", "idle": "At ease · watching the stars", "charging": "Charging dock active · studying alongside you", "happy": "Happy · a session well spent", "upgraded": "Delighted · another piece of home restored"}
		robot_mood.text = descriptions[ship_view.expression()]

func build_ship_explorer() -> void:
	var room_nav := HBoxContainer.new()
	content.add_child(room_nav)
	button(room_nav, "Overview", func(): select_room(""))
	for entry in [["cockpit", "Cockpit"], ["quarters", "Living quarters"], ["engine", "Engine room"]]:
		var id: String = entry[0]
		button(room_nav, entry[1], func(): select_room(id))
	var explorer := HBoxContainer.new()
	explorer.add_theme_constant_override("separation", 16)
	content.add_child(explorer)
	ship_view = ShipView.new()
	ship_view.interactive = true
	explorer.add_child(ship_view)
	ship_view.custom_minimum_size = Vector2(500, 360)
	# Inspector height must never enlarge the ship when a room is selected.
	ship_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ship_view.room_selected.connect(select_room)
	ship_view.object_selected.connect(inspect_object)
	ship_view.door_toggled.connect(func(_id: String, _opened: bool): update_room_panel())
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 250
	explorer.add_child(panel)
	room_panel = VBoxContainer.new()
	room_panel.add_theme_constant_override("separation", 8)
	panel.add_child(room_panel)
	select_room(selected_room)

func select_room(id: String) -> void:
	selected_room = id
	ship_view.focus_room(id)
	update_room_panel()

func room_text(text: String, font_size: int = 16) -> Label:
	var result := label(text, font_size)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room_panel.add_child(result)
	return result

func update_room_panel() -> void:
	if not is_instance_valid(room_panel):
		return
	for child in room_panel.get_children():
		room_panel.remove_child(child)
		child.queue_free()
	if selected_room.is_empty():
		room_text("A HOME IN ORBIT", 20)
		room_text("Select a room to inspect its equipment. The whole ship stays in view.")
		room_text("%d / 3 rooms restored" % Game.state.owned.filter(func(id: String): return id in ["cockpit", "quarters", "engine"]).size())
		room_text("No rush. Every session leaves a little light behind.")
		add_door_controls()
		return
	var room: Dictionary = ship_view.rooms[selected_room]
	var restored: bool = selected_room in Game.state.owned
	room_text(room.name, 20)
	room_text("RESTORED" if restored else "AWAITING CARE", 14).modulate = Color("7de1d6" if restored else "e8cf87")
	room_text(room.restored if restored else room.damaged)
	inspection_label = room_text("Click equipment in the room, or select it below.", 14)
	for i in range(room.objects.size()):
		var index: int = i
		var room_id: String = selected_room
		button(room_panel, room.objects[i], func(): inspect_object(room_id, index))
	for item in Game.balance.repairs:
		if item.id == selected_room and not restored:
			button(room_panel, "Restore · %d credits" % item.price, purchase_room)
	button(room_panel, "Back to overview", func(): select_room(""))
	add_door_controls()
	if ship_view.selected_object >= 0:
		inspect_object(selected_room, ship_view.selected_object)

func inspect_object(room_id: String, index: int) -> void:
	if selected_room != room_id:
		select_room(room_id)
	var room: Dictionary = ship_view.rooms[room_id]
	if index < 0 or index >= room.objects.size():
		return
	ship_view.selected_object = index
	inspection_label.text = room.restored_objects[index] if room_id in Game.state.owned else room.damaged_objects[index]
	ship_view.queue_redraw()

func add_door_controls() -> void:
	for entry in [["bridge", "Bridge hatch"], ["engine", "Engine hatch"]]:
		var id: String = entry[0]
		button(room_panel, entry[1] + (": OPEN" if ship_view.door_open[id] else ": CLOSED"), func(): ship_view.toggle_door(id))

func purchase_room() -> void:
	notice = Game.purchase(selected_room)
	refresh()

func refresh() -> void:
	status.text = "%s aboard %s   /   %d credits   /   %d research XP   /   Battery %d%%" % [Game.state.robot, Game.state.ship, Game.state.credits, Game.state.xp, Game.state.battery]
	message.text = notice
	update_room_panel()
	if is_instance_valid(start_button):
		var has_session := not Game.active.is_empty()
		start_button.disabled = has_session
		pause_button.disabled = not has_session
		pause_button.text = "Resume" if has_session and Game.active.paused else "Pause"
		duration.editable = not has_session
		for preset in presets.get_children():
			preset.disabled = has_session
	update_timer()

func time_text() -> String:
	if Game.active.is_empty():
		return "Ready when you are"
	var seconds := int(ceil(float(Game.active.remaining_ms) / 1000.0))
	return "%02d:%02d%s" % [int(seconds / 60), seconds % 60, " · paused" if Game.active.paused else ""]

func update_timer() -> void:
	if is_instance_valid(timer_label):
		var minutes := int(duration.value) if Game.active.is_empty() else int(Game.active.minutes)
		timer_label.text = time_text()
		reward_label.text = "On completion / +%d credits · +%d research XP · +%d%% battery (up to 100%%)" % [minutes * int(Game.balance.credits_per_minute), minutes * int(Game.balance.xp_per_minute), minutes * int(Game.balance.battery_per_minute)]
	if is_instance_valid(compact_label):
		compact_label.text = "  %s\n  %s" % [Game.state.robot, time_text()]

func confirm_cancel() -> void:
	if Game.active.is_empty():
		return
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Cancel this session? No completion rewards will be granted."
	add_child(dialog)
	dialog.confirmed.connect(func(): Game.cancel_session(); notice = "Session canceled. Begin again whenever you're ready."; refresh(); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func open_compact() -> void:
	if is_instance_valid(compact_window):
		compact_window.show()
		return
	compact_window = Window.new()
	compact_window.hide()
	compact_window.title = "Little Orbit / Focus"
	compact_window.size = Vector2i(340, 170)
	compact_window.unresizable = true
	compact_window.always_on_top = true
	compact_window.force_native = true
	add_child(compact_window)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	compact_window.add_child(column)
	compact_label = label("", 24)
	column.add_child(compact_label)
	button(column, "Pause / Resume", func(): Game.toggle_pause())
	compact_window.close_requested.connect(compact_window.hide)
	compact_window.show()
	update_timer()

func on_completed(credits: int, xp: int) -> void:
	notice = "Session complete. +%d credits, +%d XP. Your companion feels brighter." % [credits, xp]
	DisplayServer.window_request_attention()
	if Game.state.sound:
		var wave := AudioStreamWAV.new()
		wave.format = AudioStreamWAV.FORMAT_16_BITS
		wave.mix_rate = 22050
		var samples := PackedByteArray()
		samples.resize(22050)
		for i in range(11025):
			var t := float(i) / 22050.0
			var value := int(sin(TAU * (660.0 if t < 0.25 else 880.0) * t) * 7000 * (1.0 - t * 2))
			samples.encode_s16(i * 2, value)
		wave.data = samples
		sound_player.stream = wave
		sound_player.play()
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_name_edits()
		Game.advance(Time.get_ticks_msec())
		Game.save_progress()
		get_tree().quit()
