extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("COMPANION QUARTERS / Electronics workbench")
	host.charging_view = preload("res://ui/charging_dock_view.gd").new()
	host.charging_view.mode = "workbench"
	host.charging_view.actor_present = host.room_access("quarters")
	host.content.add_child(host.charging_view)
	host.button(host.content,"Use charging cradle",func(): host.show_page("charging"))
	host.button(host.content,"Open parts locker / Robot workshop",func(): host.show_page("robot"))
	host.button(host.content,"Restore companion quarters / %d credits" % Game.repair_price("quarters"),func(): host.notice = Game.purchase("quarters"); host.show_page("quarters"))
	for decoration in ["terrarium","tool_rack","relay_project"]:
		var id: String = decoration
		host.button(host.content,"Add "+id.replace("_"," ")+" / "+str(Game.balance.quarters_decor[id])+" credits",func(): host.notice = Game.buy_quarters_decor(id).message; host.show_page("quarters"))
	host.button(host.content,"Exit quarters / Return to ship",host.return_to_ship)
