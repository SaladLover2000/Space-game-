extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.station_signature = str(Game.station_contact().get("id",""))+str(Game.planet_contact().get("id",""))+Game.state.docked_station
	host.paragraph("PASSING STATIONS / Ship level %d" % Game.ship_level())
	var contact: Dictionary = Game.station_contact()
	var planet: Dictionary = Game.planet_contact()
	if not planet.is_empty():
		host.button(host.content,planet.name+" / Planetary port / %d credits / Level %d" % [planet.price,planet.level],func(): host.show_page("planet"))
	host.paragraph("Docked at "+Game.state.docked_station if not Game.state.docked_station.is_empty() else "No station in range yet." if contact.is_empty() else contact.name+" / Docking %d credits / Level %d" % [contact.price,contact.level])
	var station := preload("res://ui/station_view.gd").new()
	host.content.add_child(station)
	if Game.state.docked_station.is_empty():
		host.paragraph(Game.docking_lock())
		host.button(host.content,"Request docking / %d credits" % Game.port_rules("station").price,func(): host.notice = Game.dock_station().message; host.show_page("stations"))
	else:
		host.button(host.content,"Visit robot services",func(): host.show_page("robot"))
		host.button(host.content,"Visit engine services",func(): host.show_page("engine_bay"))
		host.button(host.content,"Undock and continue",host.depart_station)
	host.button(host.content,"Return to ship",host.return_to_ship)
