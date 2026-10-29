extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.workshop = host.Workshop.new()
	host.content.add_child(host.workshop)
