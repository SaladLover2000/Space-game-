extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.paragraph("3D SHIP / Drag to orbit freely. Shift + drag pans; wheel zooms.")
	host.ship_3d = host.Ship3D.new()
	host.content.add_child(host.ship_3d)
	host.button(host.content,"Fit 3D view",func(): host.ship_3d.reset_view())
	host.diorama_status = host.label("",14)
	host.diorama_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.content.add_child(host.diorama_status)
	var modes := HBoxContainer.new()
	host.content.add_child(modes)
	host.button(modes,"Illustrated angles (2D)",func(): host.ship_3d.set_pixel_style(true))
	host.button(modes,"3D model / Free orbit",func(): host.ship_3d.set_pixel_style(false))
