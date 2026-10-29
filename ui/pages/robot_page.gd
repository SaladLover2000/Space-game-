extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.workshop = host.Workshop.new()
	host.content.add_child(host.workshop)
	host.workshop.select_slot("robot_shell")
	host.paragraph("Autopilot: " + Game.robot_activity().replace("_"," ") + ". Your robot rests, charges or works when you leave him to it.")
