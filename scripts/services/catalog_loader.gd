class_name OrbitCatalogLoader
extends RefCounted
## Validate external data once, before Game or any page consumes it.
const EFFECT_KEYS = ["xp_percent","battery_percent","move_percent","repair_percent","cruise_percent","damage_reduction","work_lamp"]
var error_message: String = ""

func reject(path: String, detail: String) -> Dictionary:
	error_message = "%s: %s" % [path,detail]
	push_error(error_message)
	return {}

func load_all(directory: String = "res://data") -> Dictionary:
	error_message = ""
	var result: Dictionary = {}
	for filename in DirAccess.get_files_at(directory):
		if filename.get_extension() != "json": continue
		var path := directory.path_join(filename)
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			return reject(path,"line %d: %s" % [parser.get_error_line(),parser.get_error_message()])
		if not (parser.data is Array or parser.data is Dictionary): return reject(path,"expected an object or array")
		result[filename.get_basename()] = parser.data
	for name in ["balance","ship_parts","engine_modules","expansions","research"]:
		if not result.has(name): return reject("res://data/"+name+".json","required file is missing")
	var balance: Variant = result.balance
	if not balance is Dictionary: return reject("balance.json","expected an object")
	for key in ["credits_per_minute","xp_per_minute","battery_per_minute","engine_patch_price","engine_patch_points","hull_patch_price","hull_patch_points"]:
		if not nonnegative(balance.get(key)): return reject("balance.json",key+" must be a nonnegative number")
	for key in ["ports","quarters_decor","robot_care"]:
		if not balance.get(key) is Dictionary: return reject("balance.json",key+" must be an object")
	for kind in ["station","planet"]:
		var rule: Variant = balance.ports.get(kind)
		if not rule is Dictionary: return reject("balance.json","ports."+kind+" must be an object")
		for key in ["price","level"] + (["engine_condition","hull_integrity"] if kind == "station" else []):
			if not nonnegative(rule.get(key)): return reject("balance.json","ports."+kind+"."+key+" must be a nonnegative number")
	for key in ["terrarium","tool_rack","relay_project"]:
		if not nonnegative(balance.quarters_decor.get(key)): return reject("balance.json","quarters_decor."+key+" must be a nonnegative number")
	for key in ["oil_price","full_price","oil_points","full_points"]:
		if not nonnegative(balance.robot_care.get(key)): return reject("balance.json","robot_care."+key+" must be a nonnegative number")
	for name in ["ship_parts","engine_modules","expansions","research","repairs"]:
		var entries: Variant = balance.get("repairs") if name == "repairs" else result[name]
		if not entries is Array: return reject(name+".json","expected an array")
		var ids: Dictionary = {}
		for item in entries:
			if not item is Dictionary: return reject(name+".json","catalog entry must be an object")
			for key in ["id","name","description"]:
				if not item.get(key) is String or item[key].is_empty(): return reject(name+".json","entry needs a nonempty "+key)
			if ids.has(item.id): return reject(name+".json","duplicate id: "+item.id)
			ids[item.id] = true
			for key in ["price","xp"]:
				if name == "engine_modules":
					if not item.get(key) is Array or item[key].size() != 3: return reject(name+".json",item.id+" needs three "+key+" tiers")
					for amount in item[key]:
						if not nonnegative(amount): return reject(name+".json",item.id+" has an invalid "+key)
				elif not nonnegative(item.get(key)): return reject(name+".json",item.id+" has an invalid "+key)
			if name == "ship_parts":
				if not item.get("slot") is String or not item.get("effects") is Dictionary: return reject(name+".json",item.id+" requires slot and effects")
				for key in item.effects:
					if key not in EFFECT_KEYS or not nonnegative(item.effects[key]): return reject(name+".json",item.id+" has an invalid effect: "+key)
			if name in ["expansions","research"]:
				if not item.get("requires") is Array: return reject(name+".json",item.id+" requires must be an array")
	return result

func nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0
