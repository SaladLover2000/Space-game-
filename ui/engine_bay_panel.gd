extends HBoxContainer
const EngineView = preload("res://ui/engine_bay_view.gd")
signal exit_requested
var view: EngineView
var sidebar: VBoxContainer
var note: Label
var upgrade_buttons: Dictionary = {}
var flight_buttons: Dictionary = {}
var preview_buttons: Dictionary = {}
func text(parent: Node,value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label
func button(parent: Node,value: String,callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.pressed.connect(callback)
	parent.add_child(result)
	return result
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(stage)
	view = preload("res://ui/engine_bay_view.gd").new()
	view.custom_minimum_size = Vector2(620,clampf(get_viewport_rect().size.y-420,280,540))
	stage.add_child(view)
	button(stage,"Exit engine bay / Return to ship",func(): exit_requested.emit())
	note = text(stage,"")
	var tasks := HFlowContainer.new()
	stage.add_child(tasks)
	for index in range(3):
		var task: int = index
		button(tasks,["Inspect control panel","Check pump seals","Sort spare parts"][index],func(): view.choose_task(task))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340,clampf(get_viewport_rect().size.y-320,360,620))
	add_child(scroll)
	sidebar = VBoxContainer.new()
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sidebar)
	Game.changed.connect(refresh)
	refresh()
func refresh() -> void:
	if sidebar == null: return
	for child in sidebar.get_children(): sidebar.remove_child(child); child.queue_free()
	upgrade_buttons.clear()
	flight_buttons.clear()
	preview_buttons.clear()
	text(sidebar,"PROPULSION / Ship level %d" % Game.ship_level())
	text(sidebar,"Engine %d%% / Hull %d%%" % [Game.state.engine_condition,Game.state.hull_integrity])
	button(sidebar,"Patch engine / %d credits" % Game.balance.engine_patch_price,func(): note.text = Game.service_engine(false).message)
	button(sidebar,"Engine overhaul / %d credits" % Game.engine_overhaul_price(),func(): note.text = Game.service_engine(true).message)
	for item in Game.engine_modules:
		var id: String = item.id
		var tier: int = Game.state.engine_modules[id]
		text(sidebar,item.name+" / Tier %d of 3" % tier)
		text(sidebar,item.description)
		var crop := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = view.machinery.ATLAS
		atlas.region = view.machinery.source(id,mini(3,tier+2))
		crop.texture = atlas
		crop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crop.custom_minimum_size = Vector2(100,100)
		sidebar.add_child(crop)
		preview_buttons[id] = button(sidebar,"Preview next assembly",func(): view.preview_tiers = {id:mini(3,tier+1)}; view.queue_redraw(); note.text = "Preview only / no credits spent.")
		var action := button(sidebar,"Maximum tier" if tier == 3 else "Upgrade / %d credits / %d XP" % [item.price[tier],item.xp[tier]],func(): view.preview_tiers.clear(); note.text = Game.upgrade_engine_module(id).message)
		action.disabled = tier == 3
		upgrade_buttons[id] = action
	button(sidebar,"Show installed machinery",func(): view.preview_tiers.clear(); view.queue_redraw())
	for mode in ["coast","cruise","burn"]:
		var value: String = mode
		flight_buttons[mode] = button(sidebar,"Engage "+mode,func(): note.text = Game.set_flight_mode(value).message)
		var lock: String = Game.flight_lock(mode)
		if not lock.is_empty(): text(sidebar,lock)
