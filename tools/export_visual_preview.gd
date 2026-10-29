extends SceneTree
func rect_data(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.state = game.defaults()
	var path: String = OS.get_cmdline_user_args()[0]
	var art := preload("res://assets/robot_art.gd").new()
	var bay: Control = load("res://assets/robot_portrait.gd").new()
	bay.rack_progress = 1
	var manifest := {"robots":[],"lift":[],"fins":[]}
	for setup in [["white",{},0,"idle",0.0],["crimson",{"robot_paint":"robot_paint_crimson"},0,"idle",0.0],["working",{},1,"working",4.0]]:
		var entry := {"name":setup[0],"pieces":[]}
		var texture: Texture2D = art.finished_texture("robot_shell_stock",setup[1],setup[2])
		texture.get_image().save_png(path+"/preview-"+setup[0]+"-atlas.png")
		for part in art.oriented_pose(setup[1],setup[4],setup[3],false,false,setup[2]):
			entry.pieces.append({"source":rect_data(part.source),"rect":rect_data(part.rect),"rotation":part.rotation})
		manifest.robots.append(entry)
	for piece in bay.lift_layout({}): manifest.lift.append({"id":piece.id,"rect":rect_data(piece.rect),"source":rect_data(bay.maintenance.SOURCES[piece.id])})
	var ship := preload("res://assets/pixel_ship_art.gd").new()
	var equipment := {"paint":"paint_cobalt","wings":"wings_solar"}
	ship.skin_texture(ship.EXTERIOR,equipment,true).get_image().save_png(path+"/preview-painted-hull.png")
	var fins := preload("res://assets/ship_parts_art.gd").new()
	fins.finish.painted(fins.ATLAS,"paint_cobalt").get_image().save_png(path+"/preview-fins-atlas.png")
	for fin in fins.installed_parts(equipment): manifest.fins.append({"rect":rect_data(fin.rect),"source":rect_data(fins.source(fin.id)),"flip_y":fin.get("flip_y",false)})
	var bridge: Control = load("res://ui/bridge_view.gd").new()
	bridge.size = Vector2(1380,600)
	bridge.mode = "navigation"
	var actor: Dictionary = bridge.actor_state()
	bridge.background_texture().get_image().save_png(path+"/preview-bridge-bg.png")
	art.finished_texture("robot_shell_stock",{},2).get_image().save_png(path+"/preview-bridge-atlas.png")
	manifest.bridge = {"feet":[actor.feet.x,actor.feet.y],"scale":actor.scale,"pieces":[]}
	for part in art.oriented_pose({},4,"typing",false,true,2): manifest.bridge.pieces.append({"source":rect_data(part.source),"rect":rect_data(part.rect),"rotation":part.rotation})
	bridge.free()
	var file := FileAccess.open(path+"/visual-preview.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest))
	file.close()
	bay.free()
	quit()

