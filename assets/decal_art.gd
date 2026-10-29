extends RefCounted
static var textures: Dictionary = {}
const MASKS = {"orbit":["0000001100000000","0000111111000000","0011111111110000","0111000000111000","1110011110011100","0100111111001000","0011111111110000","0001111111100000","0000011110000000"],"comet":["0000000000000111","0000000000011110","0000000001111100","0000111011111000","0001111111110000","0011111111000000","0011111100000000","0001111000000000","0000110000000000"],"constellation":["0100000000001000","1110010000011100","0100111000001000","0000010001000000","0000000011100000","0001000001000100","0011100000001110","0001000000000100"]}
func draw(canvas: CanvasItem, rect: Rect2) -> void:
	var design: String = current_state().get("graffiti","none")
	if design == "custom":
		var path: String = current_state().get("custom_decal","")
		if not path.begins_with("user://decals/"): return
		if not textures.has(path):
			var image := Image.load_from_file(path)
			if image == null or image.is_empty(): return
			textures[path] = ImageTexture.create_from_image(image)
		canvas.draw_texture_rect(textures[path],rect,false,Color(1,1,1,0.9))
	elif MASKS.has(design):
		var rows: Array = MASKS[design]
		var cell := Vector2(rect.size.x/16,rect.size.y/rows.size())
		for y in range(rows.size()):
			for x in range(rows[y].length()):
				if rows[y][x] != "1": continue
				var alpha := 0.55 if (x*7+y*11)%9 == 0 else 0.90
				canvas.draw_rect(Rect2(rect.position+Vector2(x,y)*cell,cell),Color(0.93,0.83,0.61,alpha))
	if not current_state().get("callsign","").is_empty():
		canvas.draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,rect.size.y+3),current_state().callsign,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x,3,Color("e5d7b6"))

func current_state() -> Dictionary:
	return Engine.get_main_loop().root.get_node("Game").state
