extends SceneTree

var failures: int = 0
var game: Node

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = root.get_node("Game")
	game.set_process(false)
	game.save_path = "user://test_orbit_%s.json" % Time.get_ticks_usec()
	game.state = game.defaults()
	game.active = {}
	check(not game.start_session(0), "reject zero duration")
	check(not game.start_session(241), "reject oversized duration")
	check(game.start_session(25), "start valid session")
	check(not game.start_session(1), "reject overlapping session")
	game.last_tick = 1000
	game.advance(61000)
	check(game.active.remaining_ms == 1440000, "count real elapsed time in a single long frame")
	game.active.paused = true
	game.advance(121000)
	check(game.active.remaining_ms == 1440000, "paused time earns no progress")
	game.cancel_session()
	check(game.state.credits == 0 and game.state.history.is_empty(), "cancel grants no rewards")
	game.start_session(25)
	game.last_tick = 1000
	game.advance(1501000)
	check(game.state.credits == 50 and game.state.xp == 25 and game.state.battery == 33, "completion grants configured rewards")
	game.finish_session()
	game.advance(3001000)
	check(game.state.credits == 50 and game.state.history.size() == 1, "completion cannot be claimed twice")
	game.purchase("engine")
	check(game.state.credits == 0 and "engine" in game.state.owned, "purchase spends credits and persists ownership")
	game.purchase("engine")
	check(game.state.credits == 0 and game.state.owned.size() == 1, "duplicate purchase rejected")
	# Give enough currency to expose duplicate charging even if affordability passes.
	game.state.credits = 100
	game.purchase("engine")
	check(game.state.credits == 100 and game.state.owned.size() == 1, "owned item cannot charge credits again when affordable")
	game.state.credits = 0
	game.start_session(1)
	game.last_tick = 1000
	game.advance(31000)
	game.save_progress()
	game.load_progress()
	check(game.active.paused and game.active.remaining_ms == 30000, "reopen restores paused checkpoint without offline credit")
	check(game.state.history.size() == 1 and game.state.total_seconds == 1500, "history and study total survive reload")
	game.cancel_session()
	game.state.credits = 10
	game.save_progress()
	game.state.credits = 20
	game.save_progress()
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	game.load_progress()
	check(game.state.credits == 10, "corrupted primary recovers validated backup")
	check(not game.valid_snapshot({"version": 1, "credits": "bad"}), "malformed numeric state rejected")
	check(game.valid_snapshot({"version": 1}), "missing fields accept defaults")
	game.state = game.defaults()
	game.active = {}
	game.state.battery = 100
	game.start_session(1)
	game.last_tick = 1000
	game.advance(60999)
	check(game.state.credits == 0 and game.state.history.is_empty(), "no rewards one millisecond before completion")
	game.advance(61000)
	check(game.state.credits == 2 and game.state.xp == 1 and game.state.battery == 100, "one-minute boundary awards once and caps battery")
	game.load_progress()
	game.advance(200000)
	game.finish_session()
	check(game.state.credits == 2 and game.state.history.size() == 1 and game.active.is_empty(), "reload after completion cannot grant the reward again")
	var before_purchase: Dictionary = game.state.duplicate(true)
	game.purchase("cockpit")
	check(game.state == before_purchase, "insufficient funds change no state")
	game.purchase("unknown")
	check(game.state == before_purchase, "unknown item changes no state")
	game.state.credits = 100
	game.balance.repairs[0].xp = 10
	game.purchase("engine")
	check(game.state.credits == 100 and game.state.owned.is_empty(), "research requirement blocks spending and ownership")
	game.balance.repairs[0].xp = 0
	check(game.start_session(240), "maximum custom duration accepted")
	game.cancel_session()
	check(game.start_session(1), "minimum custom duration accepted")
	game.cancel_session()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	print("RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
