class_name OrbitRobotCare
extends RefCounted
## Implements one domain; Game owns state and public signals.
var game: Node

func _init(owner_game: Node) -> void:
	game = owner_game

func robot_activity() -> String:
	if game.state.hull_integrity < 100: return "field_repair"
	if not game.active.is_empty() and not game.active.paused: return "charging"
	return ["maintenance","resting","sleeping","observing"][int(game.state.cruise_seconds/40.0)%4]

func service_robot(full: bool = false) -> Dictionary:
	if game.state.robot_condition >= 100: return {"ok":false,"message":"Robot is already serviced."}
	var price: int = game.balance.robot_care.full_price if full else game.balance.robot_care.oil_price
	if game.state.credits < price: return {"ok":false,"message":"Need %d credits for robot care." % price}
	var before: Dictionary = game.state.duplicate(true)
	game.state.credits -= price
	game.state.robot_condition = mini(100,int(game.state.robot_condition)+(int(game.balance.robot_care.full_points) if full else int(game.balance.robot_care.oil_points)))
	if not game.commit_or_rollback(before): return {"ok":false,"message":game.last_error}
	return {"ok":true,"message":"Frame repaired and cleaned." if full else "Joints oiled and contacts cleaned."}

func set_robot_light(value: String) -> bool:
	if value not in ["cyan","blue","green","violet","white"]: return false
	var before: Dictionary = game.state.duplicate(true)
	game.state.robot_light = value
	return game.commit_or_rollback(before)

func robot_thought(room: String = "ship", time: float = 0) -> String:
	var lines: Array = []
	if room == "charging":
		lines = ["Battery topped up. Ready when you are.","Systems rested. Your chosen lights are back."] if game.state.battery >= 100 else ["Recharge cycle engaged. Good night...","Saving power while you focus...","Wake me after a little more study."]
	elif room == "engine":
		lines = ["Checking the coolant pressure.","This loose coupling needs a careful reseat.","I will sort these spare parts before the next burn.","A better turbopump would help our next cruise."] if game.state.engine_condition < 75 else ["Pressure steady. Checking the injector seals.","Logging nozzle temperatures.","Putting the tools back, then another inspection."]
	elif room == "cockpit":
		lines = ["Legacy navigation is offline. Tracing the fault.","Testing the next control circuit.","Rebuilding the route table, one line at a time.","Coasting safely while I check the console."] if "navigation_patch" not in game.state.research else ["Plotting a clear course.","Checking traffic beyond the next planet.","Navigation checks complete. Watching the instruments."]
	elif room == "quarters":
		lines = ["Let me assemble this little relay.","Sorting the spare fasteners.","Testing the workbench power supply.","A tidy bench makes the next repair easier."]
	else:
		lines = ["Another quiet mile between the stars.","I will check the workshop next.","Keeping an eye on the ship while you focus.","There is always a little circuit to mend."]
		if game.state.battery < 20: lines.append("Low battery... I should visit my charging cradle.")
		if game.state.robot_condition < 45: lines.append("A little oil would make these joints happier.")
	return lines[int(time/14)%lines.size()]

