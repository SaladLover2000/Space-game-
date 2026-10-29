extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func rect(rectangle: Rect2) -> Array:
	return [rectangle.position.x,rectangle.position.y,rectangle.size.x,rectangle.size.y]
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.state = game.defaults()
	game.state.robot_light = "blue"
	var path: String = OS.get_cmdline_user_args()[0]
	var art: RefCounted = load("res://assets/robot_art.gd").new()
	var engine: RefCounted = load("res://assets/engine_bay_art.gd").new()
	var manifest := {"frames":[]}
	for name in ["charging","charged","quarters-working","engine-damaged","engine-upgraded","bridge-seated"]:
		game.state.robot_condition = 100 if name in ["charged","engine-upgraded"] else 25
		var mood := "charging" if name == "charging" else "inspecting" if name in ["quarters-working","engine-damaged"] else "typing" if name == "bridge-seated" else "working" if name == "engine-upgraded" else "idle"
		var angle := 2 if name == "bridge-seated" else 3 if name in ["quarters-working","engine-damaged","engine-upgraded"] else 0
		var seated: bool = name == "bridge-seated"
		var frame := {"name":name,"pieces":[],"mood":mood,"engine":[]}
		for piece in art.oriented_pose({},4,mood,false,seated,angle):
			var filename: String = name+"-"+piece.id+".png"
			art.finished_texture(piece.id,{},angle,mood).get_image().save_png(path+"/"+filename)
			var points := []
			for vertex in art.vertices(piece): points.append([-vertex.x if angle == 3 else vertex.x,vertex.y])
			frame.pieces.append({"texture":filename,"source":rect(piece.source),"points":points})
		if name.begins_with("engine"):
			for assembly in engine.layout({"pump":3,"injector":3,"cooling":3,"nozzle":3} if name == "engine-upgraded" else {},100 if name == "engine-upgraded" else 0,name == "engine-upgraded"):
				frame.engine.append({"id":assembly.id,"tier":assembly.tier,"source":rect(assembly.source),"rect":rect(assembly.rect)})
		if name in ["charging","charged","quarters-working"]:
			var cabin: RefCounted = load("res://assets/pixel_ship_art.gd").new()
			cabin.quarters_texture(["quarters"] if name == "charged" else []).get_image().save_png(path+"/"+name+"-background.png")
		manifest.frames.append(frame)
	var file := FileAccess.open(path+"/room-preview.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest))
	file.close()
	quit()
