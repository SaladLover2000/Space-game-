extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("CHARGING CRADLE / Battery %d%%" % Game.state.battery)
	host.charging_view = preload("res://ui/charging_dock_view.gd").new()
	host.charging_view.actor_present = host.room_access("quarters")
	host.content.add_child(host.charging_view)
	host.button(host.content,"Open connecting hatches / Call robot",func(): host.open_room_hatches("quarters"))
	host.paragraph("Completed focus sessions recharge the robot. Docking itself grants no battery or study rewards.")
	host.button(host.content,"Open robot parts locker / Workshop",func(): host.show_page("robot"))
	host.button(host.content,"Exit charging area / Return to ship",host.return_to_ship)
