class_name OrbitFlight
extends RefCounted
## Implements one domain; Game owns state and public signals.
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func advance_flight(delta: float) -> void:
	if not game.state.started:
		return
	var elapsed := clampf(delta,0.0,1.0)
	if not game.state.docked_station.is_empty(): return
	if not game.flight_lock(game.state.flight_mode).is_empty(): game.state.flight_mode = "coast"
	game.state.cruise_seconds += elapsed*(1.0+game.equipment_effects().cruise_percent/100.0)*game.flight_speed()
	for event in game.asteroid_events:
		event.age += elapsed
		if event.age >= 5.0: game.apply_contact(event)
	game.asteroid_events = game.asteroid_events.filter(func(event): return event.age < 14.0)
	game.encounter_clock += elapsed
	if game.encounter_clock >= 100.0:
		game.encounter_clock = 0
		game.resolve_encounter(game.encounter_rng.randf(),game.encounter_rng.randf())
	if game.state.hull_integrity < 100 and game.robot_activity() == "field_repair":
		game.field_repair_clock += elapsed
		if game.field_repair_clock >= 30.0/(1.0+game.equipment_effects().repair_percent/100.0):
			game.field_repair_clock = 0
			game.state.hull_integrity = mini(100,int(game.state.hull_integrity)+1)
			game.save_progress()
			game.changed.emit()

func resolve_encounter(impact_roll: float, damage_roll: float) -> Dictionary:
	var impact := impact_roll < 0.25
	var damage := 2 if impact and damage_roll < 0.06 else 0
	var event := {"age":0.0,"impact":impact,"damage":damage,"resolved":false,"lane":81.0 if impact else -20.0+impact_roll*200.0,"radius":2.0+damage_roll*3.0}
	game.asteroid_events.append(event)
	return event

func apply_contact(event: Dictionary) -> void:
	if event.get("resolved",false): return
	event.resolved = true
	if event.damage > 0:
		var before: Dictionary = game.state.duplicate(true)
		game.state.hull_integrity = maxi(80,int(game.state.hull_integrity)-maxi(0,int(event.damage)-int(game.equipment_effects().damage_reduction)))
		if not game.commit_or_rollback(before): event.damage = 0

func patch_hull() -> Dictionary:
	if game.state.hull_integrity >= 100: return {"ok":false,"message":"Hull is already sound."}
	if game.state.credits < int(game.balance.hull_patch_price): return {"ok":false,"message":"Hull patch costs %d credits. Your robot can also make slow free field repairs." % int(game.balance.hull_patch_price)}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(game.balance.hull_patch_price)
	game.state.hull_integrity = mini(100,int(game.state.hull_integrity)+int(game.balance.hull_patch_points))
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Hull patched."}

func ship_level() -> int:
	var tiers := 0
	for tier in game.state.engine_modules.values(): tiers += int(tier)
	return mini(5,1+(1 if "engine" in game.state.owned else 0)+tiers/4+(1 if game.state.equipped.hull == "hull_shielded" else 0))

func flight_lock(mode: String) -> String:
	if mode == "coast": return ""
	if "engine" not in game.state.owned or game.state.engine_condition < 75: return "Restore the engine and reach 75% engine condition."
	if mode == "cruise":
		return "Upgrade turbopump and nozzle to tier 1." if game.state.engine_modules.pump < 1 or game.state.engine_modules.nozzle < 1 else ""
	if mode == "burn":
		for tier in game.state.engine_modules.values():
			if tier < 3: return "Maximum thrust requires all four engine assemblies at tier 3."
		if game.state.engine_condition < 100 or game.state.equipped.hull != "hull_shielded": return "Maximum thrust requires full engine condition and ceramic thermal cladding."
		if "navigation_patch" not in game.state.research: return "Install the navigation software rebuild."
		return ""
	return "Unknown flight mode."

func flight_speed() -> float:
	return 6.0 if game.state.flight_mode == "burn" else 2.5 if game.state.flight_mode == "cruise" else 1.0

func set_flight_mode(mode: String) -> Dictionary:
	var lock: String = game.flight_lock(mode)
	if not lock.is_empty(): return {"ok":false,"message":lock}
	if not game.state.docked_station.is_empty(): return {"ok":false,"message":"Undock before engaging propulsion."}
	var before: Dictionary = game.state.duplicate(true)
	game.state.flight_mode = mode
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Flight mode: "+mode}

