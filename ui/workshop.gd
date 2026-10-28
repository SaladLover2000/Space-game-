extends VBoxContainer
const ShipView = preload("res://assets/ship_view.gd")
const RobotPortrait = preload("res://assets/robot_portrait.gd")
const PartIcon = preload("res://ui/part_icon.gd")
const SLOTS = {"engine":"Engines", "hull":"Hull", "wings":"Fins & solar", "paint":"Paint", "antenna":"Sensors", "lights":"Lighting", "interior":"Interior themes", "repairs":"Room repairs", "robot_shell":"Robot / Chassis", "robot_visor":"Robot / Heads", "robot_arms":"Robot / Arms", "robot_legs":"Robot / Legs", "robot_core":"Robot / Chest & packs"}
var ship_view: Control
var robot_preview: Control
var engine_title: Label
var cards: GridContainer
var detail: Label
var feedback: Label
var condition: ProgressBar
var patch_button: Button
var overhaul_button: Button
var selected_slot: String = "engine"
var preview_id: String = ""
var action_buttons: Dictionary = {}
var preview_buttons: Dictionary = {}
var category_buttons: Dictionary = {}
var repair_note: Label
var category_picker: OptionButton
var category_indices: Dictionary = {}
var side_scroll: ScrollContainer
var preview_stage: VBoxContainer

func text(parent: Node, value: String, font_size: int = 17) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result

func button(parent: Node, value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func _ready() -> void:
	add_theme_constant_override("separation",10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(self,"ORBITAL DOCKYARD",24)
	var stage_height := maxf(360,get_viewport_rect().size.y-250)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation",16)
	add_child(split)
	preview_stage = VBoxContainer.new()
	preview_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stage.custom_minimum_size.x = 340
	split.add_child(preview_stage)
	ship_view = ShipView.new()
	ship_view.exterior = true
	ship_view.interactive = true
	ship_view.workshop_mode = true
	preview_stage.add_child(ship_view)
	ship_view.custom_minimum_size = Vector2(340,stage_height-90)
	ship_view.part_selected.connect(select_slot)
	robot_preview = RobotPortrait.new()
	robot_preview.preview_mode = true
	robot_preview.custom_minimum_size = Vector2(340,stage_height-90)
	preview_stage.add_child(robot_preview)
	robot_preview.hide()
	var destinations := HBoxContainer.new()
	preview_stage.add_child(destinations)
	button(destinations,"Ship upgrades",func(): select_slot("engine"))
	button(destinations,"Robot upgrades",func(): select_slot("robot_shell"))
	button(destinations,"Fit view",func(): ship_view.reset_zoom())
	feedback = text(preview_stage,"Your equipped design is shown.",15)
	feedback.modulate = Color("c8b98a")
	side_scroll = ScrollContainer.new()
	side_scroll.custom_minimum_size = Vector2(330,stage_height)
	split.add_child(side_scroll)
	var sidebar := VBoxContainer.new()
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.add_theme_constant_override("separation",10)
	side_scroll.add_child(sidebar)
	category_picker = OptionButton.new()
	sidebar.add_child(category_picker)
	for slot in SLOTS:
		category_indices[slot] = category_picker.item_count
		category_picker.add_item(SLOTS[slot])
	category_picker.item_selected.connect(func(index): select_slot(SLOTS.keys()[index]))
	detail = text(sidebar,"",17)
	engine_title = text(sidebar,"Engine condition",14)
	condition = ProgressBar.new()
	condition.custom_minimum_size.y = 20
	sidebar.add_child(condition)
	patch_button = button(sidebar,"",func(): service(false))
	overhaul_button = button(sidebar,"",func(): service(true))
	repair_note = text(sidebar,"Affordable engine patches and full overhauls. Most asteroid contacts cause no damage.",13)
	button(sidebar,"Patch hull / 5 credits",func(): feedback.text = Game.patch_hull().message; refresh())
	button(sidebar,"Use equipped design",clear_preview)
	cards = GridContainer.new()
	cards.columns = 1
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("v_separation",10)
	sidebar.add_child(cards)
	Game.changed.connect(refresh)
	resized.connect(on_resized)
	refresh()

func on_resized() -> void:
	if is_instance_valid(side_scroll):
		side_scroll.custom_minimum_size.x = clampf(size.x*0.35,300,420)
		var stage_height := maxf(360,get_viewport_rect().size.y-250)
		side_scroll.custom_minimum_size.y = stage_height
		ship_view.custom_minimum_size.y = stage_height-90
		robot_preview.custom_minimum_size.y = stage_height-90

func select_slot(slot: String) -> void:
	if not SLOTS.has(slot):
		return
	selected_slot = slot
	category_picker.select(category_indices[slot])
	ship_view.selected_slot = slot
	robot_preview.visible = slot.begins_with("robot_")
	ship_view.visible = not robot_preview.visible
	ship_view.exterior = slot != "interior" and slot != "repairs"
	clear_preview()

func clear_preview() -> void:
	preview_id = ""
	ship_view.preview_equipped = {}
	robot_preview.preview_equipped = {}
	feedback.text = "Your equipped design is shown."
	refresh()

func preview_part(id: String) -> void:
	var item: Dictionary = Game.part_by_id(id)
	if item.is_empty():
		return
	preview_id = id
	ship_view.preview_equipped = Game.state.equipped.duplicate(true)
	ship_view.preview_equipped[item.slot] = id
	robot_preview.preview_equipped = ship_view.preview_equipped.duplicate(true)
	robot_preview.queue_redraw()
	ship_view.queue_redraw()
	feedback.text = "PREVIEW ONLY / " + item.name + " - no credits spent."
	detail.text = SLOTS[selected_slot] + "\nPreview: " + item.name

func buy_part(id: String) -> void:
	var result: Dictionary = Game.buy_part(id)
	if result.ok:
		preview_id = ""
		ship_view.preview_equipped = {}
	feedback.text = result.message
	refresh()

func service(full: bool) -> void:
	var result: Dictionary = Game.service_engine(full)
	feedback.text = result.message
	refresh()

func refresh() -> void:
	if not is_instance_valid(cards):
		return
	detail.text = SLOTS[selected_slot] + ("\nPreview: " + Game.part_by_id(preview_id).name if not preview_id.is_empty() else "\nEquipped design")
	if selected_slot.begins_with("robot_"):
		var outfit: Dictionary = robot_preview.preview_equipped if not robot_preview.preview_equipped.is_empty() else Game.state.equipped
		detail.text += "\n" + robot_preview.art.build_description(outfit)
	engine_title.text = "Engine condition / Hull %d%%" % Game.state.hull_integrity
	condition.value = Game.state.engine_condition
	condition.visible = not selected_slot.begins_with("robot_")
	engine_title.visible = condition.visible
	if preview_id.is_empty():
		robot_preview.preview_equipped = {}
	var show_repairs := selected_slot in ["engine", "repairs"]
	patch_button.visible = show_repairs
	overhaul_button.visible = show_repairs
	repair_note.visible = show_repairs
	patch_button.text = "Patch +%d%%  /  %d credits" % [Game.balance.engine_patch_points, Game.balance.engine_patch_price]
	patch_button.disabled = Game.state.engine_condition >= 100
	overhaul_button.text = "Full overhaul  /  %d credits" % Game.engine_overhaul_price()
	overhaul_button.disabled = Game.state.engine_condition >= 100 and "engine" in Game.state.owned
	
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	action_buttons.clear()
	preview_buttons.clear()
	if selected_slot == "repairs":
		build_repairs()
	else:
		for item in Game.parts:
			if item.slot == selected_slot:
				build_card(item)
	ship_view.queue_redraw()

func build_card(item: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	if item.slot.begins_with("robot_"):
		var icon := RobotPortrait.new()
		icon.preview_mode = true
		icon.preview_equipped = Game.state.equipped.duplicate(true)
		icon.preview_equipped[item.slot] = item.id
		header.add_child(icon)
		icon.custom_minimum_size = Vector2(100, 130)
	else:
		var icon := PartIcon.new()
		icon.slot = item.slot
		icon.item_id = item.id
		header.add_child(icon)
	var title := text(header, item.name, 19)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(body, item.description, 15)
	var owned: bool = Game.part_owned(item.id)
	var equipped: bool = Game.state.equipped.get(item.slot) == item.id
	var lock: String = Game.part_lock(item)
	text(body, "Equipped" if equipped else "Owned  /  swap for free" if owned else "%d credits  /  %d research XP required" % [item.price, item.xp], 14)
	if not owned and not lock.is_empty():
		text(body, lock, 14).modulate = Color("e8cf87")
	var controls := HBoxContainer.new()
	body.add_child(controls)
	var id: String = item.id
	preview_buttons[id] = button(controls, "Preview", func(): preview_part(id))
	var action := button(controls, "Equipped" if equipped else "Equip free" if owned else "Buy & equip  /  %d" % item.price, func(): buy_part(id))
	action.disabled = equipped or (not owned and not lock.is_empty())
	action_buttons[id] = action

func build_repairs() -> void:
	for item in Game.balance.repairs:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(panel)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 8)
		panel.add_child(body)
		text(body, item.name, 20)
		text(body, item.description, 15)
		var id: String = item.id
		var action := button(body, "Restored" if id in Game.state.owned else "Restore  /  %d credits" % item.price, func(): feedback.text = Game.purchase(id); refresh())
		action.disabled = id in Game.state.owned
		action_buttons[id] = action
