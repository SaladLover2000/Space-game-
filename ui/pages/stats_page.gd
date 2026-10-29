extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("YOUR STUDY LOG")
	host.paragraph("%d completed sessions  /  %d minutes studied" % [Game.state.history.size(), int(Game.state.total_seconds / 60)])
	if Game.state.history.is_empty():
		host.paragraph("A blank log is a beginning. Your first session can be a small one.")
	for i in range(Game.state.history.size() - 1, -1, -1):
		var entry: Dictionary = Game.state.history[i]
		host.paragraph("%s  /  %d minutes  /  +%d credits" % [entry.date, entry.minutes, int(entry.get("credits", 0))])
