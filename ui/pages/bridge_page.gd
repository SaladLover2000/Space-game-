extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("MAIN CONTROL / A quiet watch between the stars")
	host.bridge_view = host.BridgeView.new()
	host.bridge_view.actor_present = host.room_access("cockpit")
	host.content.add_child(host.bridge_view)
	var tasks := HBoxContainer.new()
	host.content.add_child(tasks)
	host.button(tasks,"Run diagnostics",func(): host.bridge_view.set_mode("diagnostics"))
	host.button(tasks,"Work on navigation",func(): host.bridge_view.set_mode("navigation"))
	host.button(tasks,"Watch the stars",func(): host.bridge_view.set_mode("rest"))
	host.bridge_work_label = host.label("",16)
	host.content.add_child(host.bridge_work_label)
	host.button(host.content,"Exit control room / Return to ship",host.return_to_ship)
	host.button(host.content,"Open connecting hatches / Call robot",func(): host.open_room_hatches("cockpit"))
	host.button(host.content,"Engine bay",func(): host.enter_room("engine"))
	host.button(host.content,"Passing stations",func(): host.show_page("stations"))
