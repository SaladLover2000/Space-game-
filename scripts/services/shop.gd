class_name OrbitShop
extends RefCounted
## Implements one domain; Game owns state and public signals.
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func purchase(id: String) -> String:
	for item in game.balance.repairs:
		if item.id != id:
			continue
		if id in game.state.owned:
			return "Already restored."
		if game.state.xp < item.xp:
			return "More research is needed."
		if game.state.credits < item.price:
			return "Keep studying - you need %d more credits." % (item.price - game.state.credits)
		var before: Dictionary = game.state.duplicate(true)
		game.state.credits -= int(item.price)
		game.state.owned.append(id)
		if id == "engine":
			game.state.engine_condition = 100
		if not game.commit_or_rollback(before): return game.last_error
		game.repaired.emit(id)
		return "%s complete. A little more like home." % item.name
	return "Unknown component."

func part_by_id(id: String) -> Dictionary:
	return game.parts_index.get(id,{})

func part_owned(id: String) -> bool:
	var item: Dictionary = game.part_by_id(id)
	return not item.is_empty() and (item.price == 0 or id in game.state.owned)

func part_lock(item: Dictionary) -> String:
	if item.is_empty():
		return "Unknown part."
	if game.state.xp < item.xp:
		return "Requires %d research XP; you have %d." % [item.xp, game.state.xp]
	if item.has("requires") and item.requires not in game.state.owned:
		return "Complete the engine overhaul before fitting this engine."
	return ""

func buy_part(id: String) -> Dictionary:
	var item: Dictionary = game.part_by_id(id)
	if item.is_empty():
		return {"ok": false, "message": "Unknown part."}
	if game.part_owned(id):
		return game.equip_part(id)
	var lock: String = game.part_lock(item)
	if not lock.is_empty():
		return {"ok": false, "message": lock}
	if game.state.credits < item.price:
		return {"ok": false, "message": "Need %d more credits." % (item.price - game.state.credits)}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(item.price)
	game.state.owned.append(id)
	if item.slot.begins_with("robot_") and item.slot != "robot_paint":
		game.state.robot_condition = mini(100,int(game.state.robot_condition)+5)
		game.state.robot_part_condition[id] = 100
	game.state.equipped[item.slot] = id
	game.sync_equipped_sensor(item.slot,id)
	if not game.commit_or_rollback(before):
		return {"ok": false, "message": game.last_error}
	game.repaired.emit(id)
	return {"ok": true, "message": item.name + " purchased and equipped."}

func equip_part(id: String) -> Dictionary:
	var item: Dictionary = game.part_by_id(id)
	if item.is_empty() or not game.part_owned(id):
		return {"ok": false, "message": "Buy this part before equipping it."}
	if game.state.equipped.get(item.slot) == id:
		return {"ok": true, "message": "Already equipped."}
	var before: Dictionary = game.state.duplicate(true)
	game.state.equipped[item.slot] = id
	game.sync_equipped_sensor(item.slot,id)
	if not game.commit_or_rollback(before):
		return {"ok": false, "message": game.last_error}
	return {"ok": true, "message": item.name + " equipped. No charge."}

func engine_overhaul_price() -> int:
	for item in game.balance.repairs:
		if item.id == "engine":
			return int(item.price)
	return 50

func service_engine(full: bool = false) -> Dictionary:
	if game.state.engine_condition >= 100 and (not full or "engine" in game.state.owned):
		return {"ok": false, "message": "Engine is already in full condition."}
	var price: int = game.engine_overhaul_price() if full else int(game.balance.engine_patch_price)
	if game.state.credits < price:
		return {"ok": false, "message": "Need %d more credits for this repair." % (price - game.state.credits)}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= price
	game.state.engine_condition = 100 if full else mini(100, int(game.state.engine_condition) + int(game.balance.engine_patch_points))
	if full and "engine" not in game.state.owned:
		game.state.owned.append("engine")
	if not game.commit_or_rollback(before):
		return {"ok": false, "message": game.last_error}
	game.repaired.emit("engine")
	return {"ok": true, "message": "Engine overhauled." if full else "Engine patched: %d%% condition. A full overhaul unlocks replacement engines." % game.state.engine_condition}

func catalog_item(catalog: Array, id: String) -> Dictionary:
	for item in catalog:
		if item.id == id:
			return item
	return {}

func has_unlock(id: String) -> bool:
	return id in game.state.owned or id in game.state.expansions or id in game.state.research

func unlock_requirement(item: Dictionary) -> String:
	if item.is_empty():
		return "Unknown project."
	for requirement in item.requires:
		if not game.has_unlock(requirement):
			var required: Dictionary = game.catalog_item(game.expansion_catalog,requirement)
			if required.is_empty():
				required = game.catalog_item(game.research_catalog,requirement)
			return "Requires " + (required.name if not required.is_empty() else requirement.capitalize() + " restoration") + "."
	if game.state.xp < item.xp:
		return "Requires %d accumulated research XP." % item.xp
	return ""

func unlock_project(field: String, catalog: Array, id: String) -> Dictionary:
	var item: Dictionary = game.catalog_item(catalog,id)
	if item.is_empty():
		return {"ok":false,"message":"Unknown project."}
	if id in game.state[field]:
		return {"ok":false,"message":"Already completed."}
	var requirement: String = game.unlock_requirement(item)
	if not requirement.is_empty():
		return {"ok":false,"message":requirement}
	if game.state.credits < item.price:
		return {"ok":false,"message":"Need %d more credits." % (item.price-game.state.credits)}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(item.price)
	game.state[field].append(id)
	if not game.commit_or_rollback(before):
		return {"ok":false,"message":game.last_error}
	game.repaired.emit(id)
	return {"ok":true,"message":item.name + " complete."}

func build_expansion(id: String) -> Dictionary:
	return game.unlock_project("expansions",game.expansion_catalog,id)

func research_project(id: String) -> Dictionary:
	return game.unlock_project("research",game.research_catalog,id)

func equipment_effects(outfit: Dictionary = {}) -> Dictionary:
	if outfit.is_empty() and not game.effects_cache.is_empty() and game.effects_outfit == game.state.equipped:
		return game.effects_cache.duplicate()
	var result := {"xp_percent":0,"battery_percent":0,"move_percent":0,"repair_percent":0,"cruise_percent":0,"damage_reduction":0,"work_lamp":0}
	var equipped: Dictionary = game.state.equipped if outfit.is_empty() else outfit
	for id in equipped.values():
		var effects: Dictionary = game.part_by_id(id).get("effects",{})
		for key in effects:
			if result.has(key): result[key] += int(effects[key])
	result.xp_percent = mini(15,result.xp_percent)
	result.repair_percent = mini(60,result.repair_percent)
	result.damage_reduction = mini(1,result.damage_reduction)
	if outfit.is_empty():
		game.effects_outfit = game.state.equipped.duplicate()
		game.effects_cache = result.duplicate()
	return result

func effect_lines(item: Dictionary) -> Array[String]:
	var labels := {"xp_percent":"Research XP +%d%% on completed focus", "battery_percent":"Study battery recharge +%d%%", "move_percent":"Robot walking speed +%d%%", "repair_percent":"Free hull repair rate +%d%%", "cruise_percent":"Cruise scenery speed +%d%%", "damage_reduction":"Rare impact damage -%d hull point", "work_lamp":"Work lamp / illuminates active maintenance"}
	var lines: Array[String] = []
	for key in item.get("effects",{}):
		if not labels.has(key): continue
		lines.append(labels[key] if key == "work_lamp" else labels[key] % item.effects[key])
	if lines.is_empty(): lines.append("Appearance only / no stat change" if item.slot in ["robot_paint","paint","lights","interior"] else "Standard hardware / baseline performance")
	return lines

func upgrade_engine_module(id: String) -> Dictionary:
	var item: Dictionary = game.catalog_item(game.engine_modules,id)
	if item.is_empty(): return {"ok":false,"message":"Unknown engine assembly."}
	if "engine" not in game.state.owned: return {"ok":false,"message":"Restore the engine before upgrading its assemblies."}
	var tier: int = game.state.engine_modules.get(id,0)
	if tier >= 3: return {"ok":false,"message":"Assembly already at maximum tier."}
	if game.state.xp < item.xp[tier]: return {"ok":false,"message":"Requires %d research XP." % item.xp[tier]}
	if game.state.credits < item.price[tier]: return {"ok":false,"message":"Requires %d credits." % item.price[tier]}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(item.price[tier])
	game.state.engine_modules[id] = tier+1
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":item.name+" upgraded to tier %d." % (tier+1)}

func buy_quarters_decor(id: String) -> Dictionary:
	var prices: Dictionary = game.balance.quarters_decor
	if not prices.has(id): return {"ok":false,"message":"Unknown workshop decoration."}
	if "quarters" not in game.state.owned: return {"ok":false,"message":"Restore the companion quarters before adding decor."}
	if id in game.state.quarters_decor: return {"ok":true,"message":"Already installed."}
	if game.state.credits < prices[id]: return {"ok":false,"message":"More credits needed."}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= prices[id]
	game.state.quarters_decor.append(id)
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Workshop decoration installed."}

func sync_equipped_sensor(slot: String, id: String) -> void:
	if slot != "antenna": return
	game.state.sensor_mounts_configured = true
	if id == "antenna_stock": game.state.sensor_mounts.erase("dorsal")
	else: game.state.sensor_mounts.dorsal = id

func repair_price(id: String) -> int:
	return int(game.catalog_item(game.balance.repairs,id).get("price",0))

