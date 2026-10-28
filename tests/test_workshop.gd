extends SceneTree
var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://workshop_test_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.state.started = true
	game.active = {}
	check(game.state.equipped.size() == 12 and game.state.owned.is_empty(), "twelve ship and robot stock slots available without fabricated purchases")
	var before: Dictionary = game.state.duplicate(true)
	check(not game.buy_part("paint_cobalt").ok and game.state == before, "insufficient funds cannot buy or equip a cosmetic")
	check(not game.equip_part("paint_cobalt").ok and game.state == before, "unowned parts cannot be equipped")
	check(not game.buy_part("unknown").ok and game.state == before, "unknown part IDs change no state")
	game.state.credits = 1000
	before = game.state.duplicate(true)
	check(not game.buy_part("engine_hauler").ok and game.state == before, "replacement engine requires full overhaul")
	check(not game.buy_part("wings_solar").ok and game.state == before, "research gate blocks spending and ownership")
	game.state.credits = 10
	check(game.service_engine(false).ok and game.state.credits == 0 and game.state.engine_condition == 25, "affordable patch spends ten credits and restores twenty-five condition")
	check("engine" not in game.state.owned and "engine" in game.visual_repairs(), "patch gives partial engine glow without granting overhaul ownership")
	before = game.state.duplicate(true)
	check(not game.service_engine(false).ok and game.state == before, "unaffordable repair changes no condition or currency")
	game.state.credits = 1000
	check(game.service_engine(true).ok and game.state.credits == 950 and game.state.engine_condition == 100 and "engine" in game.state.owned, "complete overhaul spends catalog price and unlocks engine replacements")
	before = game.state.duplicate(true)
	check(not game.service_engine(false).ok and game.state == before, "full-condition engine cannot consume repair credits")
	check(game.buy_part("engine_hauler").ok and game.state.credits == 870 and game.state.equipped.engine == "engine_hauler", "part purchase charges once and equips its slot")
	var owned_count: int = game.state.owned.size()
	check(game.buy_part("engine_hauler").ok and game.state.credits == 870 and game.state.owned.size() == owned_count, "repeated part purchase cannot double-charge")
	check(game.equip_part("engine_stock").ok and game.state.credits == 870, "starter engine can be re-equipped for free")
	check(game.equip_part("engine_hauler").ok and game.state.credits == 870, "owned upgrade can be re-equipped for free")
	game.state.xp = 100
	check(game.buy_part("paint_cobalt").ok and game.state.equipped.paint == "paint_cobalt" and game.state.xp == 100, "paint purchase equips one slot and does not spend research XP")
	game.save_progress()
	game.load_progress()
	check(game.state.equipped.engine == "engine_hauler" and game.state.equipped.paint == "paint_cobalt" and game.state.engine_condition == 100, "equipped parts and repair condition survive disk reload")
	var good_path: String = game.save_path
	game.save_path = "user://missing_workshop_%s/save.json" % Time.get_ticks_usec()
	before = game.state.duplicate(true)
	check(not game.buy_part("lights_violet").ok and game.state == before, "failed persistence rolls back currency, ownership and equipment")
	game.save_path = good_path
	check(game.save_progress() and game.last_error.is_empty(), "successful retry clears a recovered save error")
	game.state.equipped.engine = "paint_cobalt"
	game.save_progress()
	game.load_progress()
	check(game.state.equipped.engine == "engine_stock", "wrong-slot equipment in a save resets safely")
	game.state.erase("equipped")
	game.state.erase("engine_condition")
	game.save_progress()
	game.load_progress()
	check(game.state.equipped.size() == 12 and game.state.engine_condition == 100 and "engine" in game.state.owned, "older saves gain default equipment and preserve completed engine repair")
	check(not game.valid_snapshot({"version":1,"equipped":{"paint":5}}), "malformed equipped state is rejected")
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.show_page("shop")
	await process_frame
	var shop: Control = scene.workshop
	var slot_points := {"engine":Vector2(249,80),"hull":Vector2(199,79),"wings":Vector2(215,25),"antenna":Vector2(170,35),"paint":Vector2(130,79),"lights":Vector2(60,110),"interior":Vector2(60,75)}
	for slot in slot_points:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = shop.ship_view.view_transform() * slot_points[slot]
		shop.ship_view._gui_input(event)
		event.pressed = false
		shop.ship_view._gui_input(event)
		check(shop.selected_slot == slot, "ship hotspot opens the " + slot + " category")
	shop.select_slot("engine")
	before = game.state.duplicate(true)
	shop.preview_buttons.engine_ion.pressed.emit()
	check(shop.ship_view.equipment().engine == "engine_ion" and game.state == before, "preview changes only displayed equipment, never saved progress")
	await capture("ship-workshop")
	scene.content.get_parent().scroll_vertical = 450
	await process_frame
	await capture("shop-parts-catalog")
	scene.content.get_parent().scroll_vertical = 0
	shop.clear_preview()
	check(shop.ship_view.equipment() == game.state.equipped, "cancel preview restores equipped design")
	shop.select_slot("paint")
	var credits_before: int = game.state.credits
	shop.action_buttons.paint_copper.pressed.emit()
	check(game.state.equipped.paint == "paint_copper" and game.state.credits == credits_before - 25, "actual shop Buy button charges and equips the selected cosmetic")
	shop.category_buttons.interior.pressed.emit()
	shop.preview_buttons.interior_habitat.pressed.emit()
	check(not shop.ship_view.exterior and shop.ship_view.equipment().interior == "interior_habitat" and game.state.equipped.interior == "interior_stock", "interior theme preview uses cutaway without equipping for free")
	await capture("interior-theme-preview")
	shop.preview_buttons.interior_lab.pressed.emit()
	check(shop.ship_view.equipment().interior == "interior_lab" and game.state.equipped.interior == "interior_stock", "laboratory theme can be previewed without granting ownership")
	await capture("interior-lab-preview")
	shop.action_buttons.interior_habitat.pressed.emit()
	game.load_progress()
	check(game.state.equipped.interior == "interior_habitat", "purchased interior theme survives reload")
	game.start_session(25)
	var session_id: String = game.active.id
	shop.select_slot("wings")
	shop.preview_part("wings_solar")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.id == session_id and game.active.remaining_ms == 1440000, "workshop previews leave the study countdown intact")
	game.cancel_session()
	root.size = Vector2i(920,680)
	root.content_scale_size = Vector2i(920,680)
	await process_frame
	await process_frame
	check(scene.content.size.x <= 872 and shop.cards.columns == 1, "workshop fits the minimum width with one-column cards")
	root.size = Vector2i(1600,900)
	root.content_scale_size = Vector2i(1600,900)
	scene.show_page("interior")
	await process_frame
	await capture("side-view-habitat")
	game.state.owned.erase("engine")
	game.state.engine_condition = 100
	check(game.service_engine(true).ok and "engine" in game.state.owned, "a fully patched engine can still complete its overhaul to unlock replacements")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	scene.queue_free()
	await process_frame
	print("WORKSHOP RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
