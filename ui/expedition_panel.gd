extends VBoxContainer
const ShipView = preload("res://assets/ship_view.gd")
var view: Control
var cards: GridContainer
var feedback: Label
var actions: Dictionary = {}
var previews: Dictionary = {}

func label(parent: Node, value: String, font_size: int = 16) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	parent.add_child(node)
	return node

func button(parent: Node, title: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = title
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func _ready() -> void:
	add_theme_constant_override("separation",12)
	label(self,"GROW YOUR STARSHIP",25)
	label(self,"Begin with the upper deck. Add connected rooms below it, then use the lab to research new systems. Research XP is a milestone; only credits are spent.")
	view = ShipView.new()
	view.interactive = true
	add_child(view)
	view.custom_minimum_size.y = 380
	view.room_selected.connect(func(id): view.focus_room(id))
	var tools := HBoxContainer.new()
	add_child(tools)
	button(tools,"Fit whole ship",func(): view.preview_expansion = ""; view.reset_zoom())
	feedback = label(self,"Choose a construction site to preview its attachment.")
	feedback.modulate = Color("7de1d6")
	cards = GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation",12)
	cards.add_theme_constant_override("v_separation",12)
	add_child(cards)
	resized.connect(func(): cards.columns = 2 if size.x >= 1000 else 1)
	Game.changed.connect(refresh)
	refresh()

func preview(id: String) -> void:
	if Game.catalog_item(Game.expansion_catalog,id).is_empty(): return
	view.preview_expansion = id
	view.reset_zoom()
	feedback.text = "Preview: " + Game.catalog_item(Game.expansion_catalog,id).name + ". No credits spent."

func purchase(id: String, research: bool = false) -> void:
	var result: Dictionary = Game.research_project(id) if research else Game.build_expansion(id)
	feedback.text = result.message
	if result.ok:
		view.preview_expansion = ""
		view.sync_layout()
		view.reset_zoom()
	refresh()

func refresh() -> void:
	if not is_instance_valid(cards): return
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	actions.clear()
	previews.clear()
	for is_research in [false,true]:
		var catalog: Array = Game.research_catalog if is_research else Game.expansion_catalog
		for item in catalog:
			var panel := PanelContainer.new()
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cards.add_child(panel)
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation",8)
			panel.add_child(column)
			label(column,("LAB PROJECT / " if is_research else "NEW DECK / ")+item.name,19)
			label(column,item.description,15)
			var owned: bool = item.id in (Game.state.research if is_research else Game.state.expansions)
			label(column,"Completed" if owned else "%d credits  /  %d accumulated research XP" % [item.price,item.xp],14)
			var requirement: String = Game.unlock_requirement(item)
			if not owned and not requirement.is_empty(): label(column,requirement,14)
			var controls := HBoxContainer.new()
			column.add_child(controls)
			var id: String = item.id
			var research: bool = is_research
			if not research: previews[id] = button(controls,"Preview site",func(): preview(id))
			var action := button(controls,"Completed" if owned else "Research" if research else "Build room",func(): purchase(id,research))
			action.disabled = owned or not requirement.is_empty()
			actions[id] = action
