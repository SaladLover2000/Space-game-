extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.expedition_panel = host.ExpeditionPanel.new()
	host.content.add_child(host.expedition_panel)
