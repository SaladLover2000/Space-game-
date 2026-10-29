extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("PLANETARY APPROACH / Ship level %d" % Game.ship_level())
	var planet: Dictionary = Game.planet_contact()
	host.paragraph("No planetary port in approach range." if planet.is_empty() else planet.name+" / Port clearance %d credits / Level %d" % [planet.price,planet.level])
	var planet_view := preload("res://ui/station_view.gd").new()
	planet_view.planet_index = planet.get("index",0)
	host.content.add_child(planet_view)
	host.paragraph(Game.landing_lock())
	host.button(host.content,"Request planetary entry / %d credits" % Game.port_rules("planet").price,func(): host.notice = Game.land_planet().message; host.show_page("stations"))
	host.button(host.content,"Return to ship",host.return_to_ship)
