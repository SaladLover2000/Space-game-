extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.content.add_child(host.ShipView.new())
	host.paragraph("A quiet corner of the universe. A small companion. One session at a time.")
	host.button(host.content, "Continue your journey" if Game.state.started else "Begin your journey", func(): host.show_page("ship" if Game.state.started else "setup"))
	host.paragraph("Your progress stays with you. Missing a day never hurts your robot.")
