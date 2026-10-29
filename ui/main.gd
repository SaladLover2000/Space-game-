extends Control

const PAGE_SCRIPTS = {
	"menu":preload("res://ui/pages/menu_page.gd"),
	"setup":preload("res://ui/pages/setup_page.gd"),
	"interior":preload("res://ui/pages/interior_page.gd"),
	"ship":preload("res://ui/pages/ship_page.gd"),
	"3d":preload("res://ui/pages/3d_page.gd"),
	"bridge":preload("res://ui/pages/bridge_page.gd"),
	"engine_bay":preload("res://ui/pages/engine_bay_page.gd"),
	"quarters":preload("res://ui/pages/quarters_page.gd"),
	"charging":preload("res://ui/pages/charging_page.gd"),
	"stations":preload("res://ui/pages/stations_page.gd"),
	"planet":preload("res://ui/pages/planet_page.gd"),
	"build":preload("res://ui/pages/build_page.gd"),
	"shop":preload("res://ui/pages/shop_page.gd"),
	"robot":preload("res://ui/pages/robot_page.gd"),
	"stats":preload("res://ui/pages/stats_page.gd"),
	"settings":preload("res://ui/pages/settings_page.gd"),
}
var active_page: RefCounted

const ChargingView = preload("res://ui/charging_dock_view.gd")
const EnginePanel = preload("res://ui/engine_bay_panel.gd")
const ShipView = preload("res://assets/ship_view.gd")
const RobotPortrait = preload("res://assets/robot_portrait.gd")
const FocusDock = preload("res://ui/focus_dock.gd")
const Ship3D = preload("res://ui/ship_3d.gd")
const BridgeView = preload("res://ui/bridge_view.gd")
const ExpeditionPanel = preload("res://ui/expedition_panel.gd")
var focus_dock: FocusDock
var contact_button: Button
var station_signature: String = ""
var contact_elapsed: float = 1.0
var contact_label: String = ""
var charging_view: ChargingView
var engine_panel: EnginePanel
var room_hatches := {"bridge":true,"engine":true}
var companion_room: String = "quarters"
var companion_seated: bool = false
var entering_room: bool = false
var bridge_view: BridgeView
var bridge_work_label: Label
var ship_3d: Ship3D
var diorama_status: Label
var expedition_panel: ExpeditionPanel
var nav_buttons: Dictionary = {}
var page_transition: Tween
const Workshop = preload("res://ui/workshop.gd")
var workshop: Workshop
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
var compact_panel: PanelContainer
var compact_hide_button: Button
var compact_pause_button: Button
var compact_label: Label
var sound_player: AudioStreamPlayer
var ship_view: ShipView
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
	if not Game.data_error.is_empty():
		var error_label := Label.new()
		error_label.text = "Game data could not be loaded.\n"+Game.data_error
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(error_label)
		set_process(false)
		return
	theme = preload("res://ui/orbit_theme.tres")
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var title := label("LITTLE ORBIT  /  Your home between the stars", 23)
	title.modulate = Color("7de1d6")
	root.add_child(title)
	status = label("", 15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status)
	var nav := HFlowContainer.new()
	root.add_child(nav)
	for entry in [["Ship","ship"],["Bridge","bridge"],["3D view","3d"],["Build & research","build"],["Robot","robot"],["Shop","shop"],["Study log","stats"],["Settings","settings"]]:
		var target: String = entry[1]
		nav_buttons[target] = button(nav,entry[0],func(): show_page(target))
	contact_button = button(nav,"Contacts",func(): show_page("stations"))
	button(nav,"Focus bar",func(): focus_dock.reveal())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	focus_dock = FocusDock.new()
	root.add_child(focus_dock)
	focus_dock.cancel_requested.connect(confirm_cancel)
	message = label("", 14)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.modulate = Color("e8cf87")
	root.add_child(message)
	message.visible = false
	Game.changed.connect(refresh)
	Game.completed.connect(on_completed)
	Game.storage_error.connect(func(text: String): notice = text; refresh())
	Game.storage_recovered.connect(func(previous: String):
		if notice == previous:
			notice = ""
			refresh())
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	build_chime()
	name_autosave = Timer.new()
	name_autosave.one_shot = true
	name_autosave.wait_time = 0.45
	name_autosave.timeout.connect(flush_name_edits)
	add_child(name_autosave)
	notice = Game.last_error
	show_page("ship" if Game.state.started else "menu")
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
	if is_instance_valid(ship_view) and not entering_room:
		room_hatches = ship_view.door_open.duplicate()
		companion_room = "cockpit" if ship_view.robot_position.x < 95 else "engine" if ship_view.robot_position.x > 172 else "quarters"
		companion_seated = ship_view.robot_seated
	flush_name_edits()
	if not Game.state.started and page != "menu":
		page = "setup"
	current_page = page
	focus_dock.context_hidden = page in ["shop","robot"]
	if page in ["shop","robot"] and is_instance_valid(compact_panel): compact_panel.hide()
	for target in nav_buttons:
		nav_buttons[target].modulate = Color("7de1d6") if target == page else Color.WHITE
	if page_transition: page_transition.kill()
	if active_page: active_page.teardown()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	timer_label = focus_dock.timer
	reward_label = focus_dock.reward
	start_button = focus_dock.start_button
	pause_button = focus_dock.pause_button
	duration = focus_dock.duration
	presets = focus_dock.presets
	active_page = PAGE_SCRIPTS.get(page,PAGE_SCRIPTS.menu).new(self)
	active_page.build()
	refresh()
	if page in ["shop","robot"]:
		if page_transition: page_transition.kill()
		content.modulate.a = 0.0
		page_transition = create_tween()
		page_transition.tween_property(content,"modulate:a",1.0,0.15)
	else:
		content.modulate.a = 1.0

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
		name_hint.text = "Saving names..."

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
	contact_elapsed += _delta
	if contact_elapsed >= 0.25:
		contact_elapsed = 0.0
		refresh_contacts()
	update_timer()
	if is_instance_valid(diorama_status) and is_instance_valid(ship_3d):
		diorama_status.text = ship_3d.damage_description()
	if is_instance_valid(bridge_work_label) and is_instance_valid(bridge_view):
		bridge_work_label.text = bridge_view.work_state()
	if is_instance_valid(drift_status):
		drift_status.text = "Study / " + time_text()
	if is_instance_valid(robot_mood) and is_instance_valid(ship_view):
		var descriptions := {"working": "Working / " + ship_view.robot_art.work_action(ship_view.clock).description, "sleeping":"Sleeping / resting in the bunk", "sad": "Resting  /  low battery", "idle": "At ease  /  watching the stars", "charging": "Charging dock active  /  studying alongside you", "happy": "Happy  /  a session well spent", "upgraded": "Delighted  /  another piece of home restored"}
		robot_mood.text = descriptions[ship_view.expression()]

func build_ship_explorer() -> void:
	var room_nav := HBoxContainer.new()
	content.add_child(room_nav)
	button(room_nav, "Overview", func(): select_room(""))
	for entry in [["cockpit", "Cockpit"], ["quarters", "Living quarters"], ["engine", "Engine room"]]:
		var id: String = entry[0]
		button(room_nav, entry[1], func(): enter_room(id))
	for item in Game.expansion_catalog:
		if item.id in Game.state.expansions:
			var room_id: String = item.id
			button(room_nav,item.name,func(): select_room(room_id))
	var explorer := HBoxContainer.new()
	explorer.add_theme_constant_override("separation", 16)
	content.add_child(explorer)
	ship_view = ShipView.new()
	ship_view.interactive = true
	explorer.add_child(ship_view)
	ship_view.custom_minimum_size = Vector2(420,clampf(get_viewport_rect().size.y-400,300,620))
	# Inspector height must never enlarge the ship when a room is selected.
	ship_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ship_view.immersive_routes = true
	ship_view.door_open = room_hatches.duplicate()
	for key in room_hatches: ship_view.door_progress[key] = 1.0 if room_hatches[key] else 0.0
	ship_view.robot_position = {"cockpit":Vector2(80,103),"quarters":Vector2(115,103),"engine":Vector2(205,103)}.get(companion_room,Vector2(115,103))
	ship_view.robot_destination = ship_view.robot_position
	if companion_room == "cockpit" and companion_seated:
		ship_view.robot_position = ship_view.PILOT_SEAT
		ship_view.robot_seated = true
		ship_view.manual_task = "navigation"
	ship_view.room_selected.connect(enter_room)
	ship_view.object_selected.connect(route_object)
	var zoom_controls := HBoxContainer.new()
	content.add_child(zoom_controls)
	button(zoom_controls, "- Zoom out", func(): ship_view.change_zoom(1.0 / 1.15))
	button(zoom_controls, "+ Zoom in", func(): ship_view.change_zoom(1.15))
	button(zoom_controls, "Fit ship", func(): ship_view.reset_zoom())
	zoom_controls.add_child(label("Drag left mouse to pan  /  wheel to zoom", 14))
	button(zoom_controls,"Passing stations",func(): show_page("stations"))
	ship_view.seating_changed.connect(func(_seated: bool): update_room_panel())
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
	if not selected_room.is_empty() and not ship_view.rooms.has(selected_room):
		selected_room = ""
	if selected_room.is_empty():
		room_text("A HOME IN ORBIT", 20)
		room_text("Select a room to inspect its equipment. The whole ship stays in view.")
		room_text("%d / 3 rooms restored" % Game.state.owned.filter(func(id: String): return id in ["cockpit", "quarters", "engine"]).size())
		room_text("No rush. Every session leaves a little light behind.")
		add_door_controls()
		return
	var room: Dictionary = ship_view.rooms[selected_room]
	var restored: bool = selected_room in Game.state.owned or selected_room in Game.state.expansions
	room_text(room.name, 20)
	room_text("RESTORED" if restored else "AWAITING CARE", 14).modulate = Color("7de1d6" if restored else "e8cf87")
	room_text(room.restored if restored else room.damaged)
	inspection_label = room_text("Click equipment in the room, or select it below.", 14)
	for i in range(room.objects.size()):
		var index: int = i
		var room_id: String = selected_room
		button(room_panel, room.objects[i], func(): activate_object(room_id,index))
	for item in Game.balance.repairs:
		if item.id == selected_room and not restored:
			button(room_panel, "Restore  /  %d credits" % item.price, purchase_room)
	button(room_panel, "Back to overview", func(): select_room(""))
	add_door_controls()
	if selected_room == "lab":
		button(room_panel,"Open laboratory research",func(): show_page("build"))
	if selected_room == "cockpit":
		button(room_panel,"Enter immersive control room",func(): show_page("bridge"))
	if ship_view.selected_object >= 0:
		inspect_object(selected_room, ship_view.selected_object)

func activate_object(room_id: String, index: int) -> void:
	inspect_object(room_id,index)
	if room_id == "cockpit" and index == 2:
		ship_view.toggle_seat()

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

	if selected_room == "cockpit":
		var seat_action := "Stand up" if ship_view.robot_seated else "Cancel sitting" if ship_view.seat_requested else "Sit in pilot seat"
		button(room_panel,seat_action,func(): ship_view.toggle_seat())
		room_text("Seated at the controls." if ship_view.robot_seated else "Walking to the seat. Open any closed hatch on the route." if ship_view.seat_requested else "Click the pilot seat to sit; choose another room to get up.",14)

func purchase_room() -> void:
	notice = Game.purchase(selected_room)
	refresh()

func refresh() -> void:
	status.text = "%s aboard %s   /   %d credits   /   %d research XP   /   Battery %d%%" % [Game.state.robot, Game.state.ship, Game.state.credits, Game.state.xp, Game.state.battery]
	if Game.state.hull_integrity < 100: status.text += " / Hull %d%%" % Game.state.hull_integrity
	message.text = notice
	message.visible = not notice.is_empty()
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
	return "%02d:%02d%s" % [int(seconds / 60), seconds % 60, "  /  paused" if Game.active.paused else ""]

func update_timer() -> void:
	if is_instance_valid(focus_dock):
		focus_dock.refresh()
	if is_instance_valid(compact_label):
		compact_label.text = "%s\n%s" % [Game.state.robot, time_text() if not Game.active.is_empty() else "Ready"]

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
	if is_instance_valid(compact_panel):
		compact_panel.show()
		update_timer()
		return
	compact_panel = PanelContainer.new()
	root.add_child(compact_panel)
	root.move_child(compact_panel, 3)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	compact_panel.add_child(row)
	compact_label = label("", 32)
	compact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(compact_label)
	compact_pause_button = button(row, "Pause / Resume", func(): Game.toggle_pause())
	compact_hide_button = button(row, "Hide timer", func(): compact_panel.hide())
	update_timer()

func on_completed(credits: int, xp: int) -> void:
	notice = "Session complete. +%d credits, +%d XP. Your companion feels brighter." % [credits, xp]
	DisplayServer.window_request_attention()
	if Game.state.sound:
		sound_player.play()
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_name_edits()
		focus_dock.flush_task()
		Game.advance(Time.get_ticks_msec())
		Game.save_progress()
		get_tree().quit()

func room_access(id: String) -> bool:
	if companion_room == id: return true
	if (companion_room == "engine" or id == "engine") and not room_hatches.engine: return false
	if (companion_room == "cockpit" or id == "cockpit") and not room_hatches.bridge: return false
	return true

func enter_room(id: String) -> void:
	if is_instance_valid(ship_view): room_hatches = ship_view.door_open.duplicate()
	var allowed := room_access(id)
	if allowed: companion_room = id
	entering_room = true
	selected_room = ""
	show_page("bridge" if id == "cockpit" else "engine_bay" if id == "engine" else "quarters" if id == "quarters" else "build")
	entering_room = false

func route_object(id: String, index: int) -> void:
	if id == "quarters" and index == 0:
		enter_room(id)
		show_page("charging")
		return
	if id == "quarters" and index == 2:
		show_page("robot")
		return
	enter_room(id)

func open_room_hatches(id: String) -> void:
	room_hatches.bridge = true
	room_hatches.engine = true
	companion_room = id
	if is_instance_valid(bridge_view): bridge_view.actor_present = true
	if is_instance_valid(engine_panel): engine_panel.view.actor_present = true
	if is_instance_valid(charging_view): charging_view.actor_present = true

func return_to_ship() -> void:
	if is_instance_valid(bridge_view): companion_seated = bridge_view.actor_present and bridge_view.mode in ["navigation","rest"]
	selected_room = ""
	show_page("ship")

func build_station_page() -> void:
	PAGE_SCRIPTS.stations.new(self).build()

func apply_setting(toggle: CheckButton, key: String, value: bool) -> void:
	if not Game.set_setting(key,value):
		toggle.set_pressed_no_signal(Game.state[key])
		notice = Game.last_error
		refresh()

func depart_station() -> void:
	if Game.undock_station(): return_to_ship()
	else:
		notice = Game.last_error
		refresh()

func refresh_contacts() -> void:
	var contact: Dictionary = Game.station_contact()
	var planet: Dictionary = Game.planet_contact()
	var nearest: Dictionary = contact if not contact.is_empty() else planet
	var text := "Contacts / none in range" if nearest.is_empty() else "%s / %d cr / level %d" % [nearest.name,nearest.price,nearest.level]
	if is_instance_valid(contact_button) and text != contact_label:
		contact_button.text = text
		contact_label = text
	if current_page == "stations":
		var signature: String = str(contact.get("id",""))+str(planet.get("id",""))+Game.state.docked_station
		if signature != station_signature:
			station_signature = signature
			call_deferred("show_page","stations")

func build_chime() -> void:
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
