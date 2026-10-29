extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := root.get_node("Game")
	game.set_process(false)
	game.state = game.defaults()
	game.state.expansions = ["lab"]
	var viewer: Control = load("res://ui/ship_3d.gd").new()
	root.add_child(viewer)
	await process_frame
	viewer.set_process(false)
	var triangles := []
	for node in viewer.model.get_children():
		if not node is MeshInstance3D or not node.visible: continue
		var material: StandardMaterial3D = node.material_override
		if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
		var faces: PackedVector3Array = node.mesh.get_faces()
		for index in range(0,faces.size(),3):
			var points := []
			for offset in range(3):
				var point: Vector3 = node.transform*faces[index+offset]
				points.append([point.x,point.y,point.z])
			triangles.append({"points":points,"color":[material.albedo_color.r,material.albedo_color.g,material.albedo_color.b]})
	var output := FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	output.store_string(JSON.stringify(triangles))
	output.close()
	quit()

