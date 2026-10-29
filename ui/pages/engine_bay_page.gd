extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("ENGINE BAY / Propulsion and thermal systems")
	host.engine_panel = preload("res://ui/engine_bay_panel.gd").new()
	host.content.add_child(host.engine_panel)
	host.engine_panel.view.actor_present = host.room_access("engine")
	host.engine_panel.exit_requested.connect(host.return_to_ship)
	host.button(host.content,"Open connecting hatches / Call robot",func(): host.open_room_hatches("engine"))
