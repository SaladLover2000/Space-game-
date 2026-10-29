class_name OrbitDocking
extends RefCounted
## Implements one domain; Game owns state and public signals.
const Geometry = preload("res://scripts/contact_geometry.gd")
const STATION_PERIOD = 240.0
const STATION_NAMES = ["Wayfarer Exchange","Kepler Repair Dock","Aster Research Port"]
const PLANET_NAMES = ["Copper Reach","Thalassa","Amethyst Moon"]
const SENSOR_CONTACT_PHASE = 130.0
const BASE_CONTACT_PHASE = 180.0
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func station_contact() -> Dictionary:
	var phase := fposmod(game.state.cruise_seconds,STATION_PERIOD)
	var sensor_range := SENSOR_CONTACT_PHASE if game.has_docking_sensor() else BASE_CONTACT_PHASE
	if phase < sensor_range: return {}
	return {"id":"station_%d" % (int(game.state.cruise_seconds/STATION_PERIOD)%STATION_NAMES.size()),"name":STATION_NAMES[int(game.state.cruise_seconds/STATION_PERIOD)%STATION_NAMES.size()],"price":game.port_rules("station").price,"level":game.port_rules("station").level}

func docking_lock() -> String:
	if not game.state.docked_station.is_empty(): return "Already docked."
	if game.station_contact().is_empty(): return "No station is currently in sensor range."
	if game.ship_level() < game.port_rules("station").level: return "Station approach requires overall ship level %d." % int(game.port_rules("station").level)
	if not game.has_docking_sensor(): return "Fit docking LiDAR or rendezvous radar for approach."
	if game.state.engine_condition < game.port_rules("station").engine_condition or game.state.hull_integrity < game.port_rules("station").hull_integrity: return "Approach requires engine %d%% and hull %d%%." % [game.port_rules("station").engine_condition,game.port_rules("station").hull_integrity]
	if game.state.credits < game.port_rules("station").price: return "Station docking costs %d credits." % int(game.port_rules("station").price)
	return ""

func dock_station() -> Dictionary:
	var lock: String = game.docking_lock()
	if not lock.is_empty(): return {"ok":false,"message":lock}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(game.port_rules("station").price)
	game.state.docked_station = game.station_contact().id
	game.state.station_visits += 1
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Docking complete. Focus time continues."}

func undock_station() -> bool:
	var before: Dictionary = game.state.duplicate(true)
	game.state.docked_station = ""
	return game.commit_or_rollback(before)

func planet_contact() -> Dictionary:
	for index in range(Geometry.PLANET_COUNT):
		var x := Geometry.planet_x(index,game.state.cruise_seconds)
		if x >= Geometry.APPROACH_MIN_X and x <= Geometry.APPROACH_MAX_X:
			return {"id":"planet_%d" % index,"index":index,"name":PLANET_NAMES[index],"price":game.port_rules("planet").price,"level":game.port_rules("planet").level}
	return {}
func landing_lock() -> String:
	if not game.state.docked_station.is_empty(): return "Depart the current port before approaching another destination."
	if game.planet_contact().is_empty(): return "No planetary port is within approach range."
	if game.ship_level() < game.port_rules("planet").level: return "Planetary approach requires overall ship level %d." % int(game.port_rules("planet").level)
	if game.state.engine_condition < 100 or game.state.hull_integrity < 100: return "Atmospheric approach requires full engine and hull condition."
	if game.state.equipped.hull != "hull_shielded" or game.state.engine_modules.cooling < 2: return "Fit ceramic thermal cladding and tier 2 cooling for entry."
	if "navigation_patch" not in game.state.research or not game.has_docking_sensor(): return "Install navigation software and an approach sensor."
	if game.state.credits < game.port_rules("planet").price: return "Planetary port clearance costs %d credits." % int(game.port_rules("planet").price)
	return ""
func land_planet() -> Dictionary:
	var lock: String = game.landing_lock()
	if not lock.is_empty(): return {"ok":false,"message":lock}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= int(game.port_rules("planet").price)
	game.state.docked_station = game.planet_contact().id
	game.state.station_visits += 1
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Planetary port reached. Your focus session continues."}

func port_rules(kind: String) -> Dictionary:
	return game.balance.ports[kind]

