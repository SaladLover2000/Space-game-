extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("INSIDE / " + Game.state.ship)
	host.build_ship_explorer()
	host.ship_view.custom_minimum_size.y = clampf(host.get_viewport_rect().size.y-400,300,620)
	host.drift_status = host.label("")
	host.content.add_child(host.drift_status)
	host.button(host.content, "Study controls", func(): host.show_page("ship"))
