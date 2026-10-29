extends RefCounted
## Material-aware panel paint: dark mechanisms and optics retain their own colors.
static var cache: Dictionary = {}
const JOBS = {"paint_ivory":"e9dfbd","paint_crimson":"a53c43","paint_sage":"56785b","paint_violet":"77649e","paint_charcoal":"444e60","robot_paint_sand":"c2a777","robot_paint_cobalt":"315d9a","robot_paint_sage":"56785b","robot_paint_crimson":"a53c43","robot_paint_gold":"b89149","paint_cobalt":"315d9a","paint_copper":"b46f42"}
func painted(texture: Texture2D, finish: String, regions: Dictionary = {}, cutaway: bool = false) -> Texture2D:
	if not JOBS.has(finish): return texture
	var key := str(texture.get_instance_id())+finish+str(cutaway)
	if cache.has(key): return cache[key]
	var image: Image = texture.get_image()
	if image.is_compressed(): image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var color := Color(JOBS[finish])
	var pieces := []
	if regions.is_empty(): pieces.append({"role":"hull","rect":Rect2i(0,0,width,height)})
	else:
		for id in regions:
			for side in regions[id]:
				var r: Array = regions[id][side]
				pieces.append({"role":id,"rect":Rect2i(r[0],r[1],r[2],r[3])})
	for piece in pieces:
		var rect: Rect2i = piece.rect
		for y in range(maxi(0,rect.position.y),mini(height,rect.end.y)):
			for x in range(maxi(0,rect.position.x),mini(width,rect.end.x)):
				var index := (y*width+x)*4
				if bytes[index+3] < 40: continue
				var r := bytes[index]/255.0
				var g := bytes[index+1]/255.0
				var b := bytes[index+2]/255.0
				var value := (r+g+b)/3.0
				var is_armor := minf(r,minf(g,b)) > 0.37 and maxf(r,maxf(g,b))-minf(r,minf(g,b)) < 0.28
				if piece.role == "hull":
					if x < width*0.39 and y > height*0.34 and y < height*0.59 and g > b*0.7 and b > r*1.3: continue
					if cutaway and y > height*0.41 and y < height*0.63 and x < width*0.87: continue
					is_armor = is_armor or (b > r*1.3 and b > g*1.1 and g < 0.55)
				if not is_armor: continue
				var u := float(x-rect.position.x)/maxi(1,rect.size.x)
				var v := float(y-rect.position.y)/maxi(1,rect.size.y)
				var primary := true
				if "shell" in piece.role: primary = u < 0.30 or u > 0.70 or v < 0.25
				elif "visor" in piece.role: primary = v < 0.42 or u < 0.16 or u > 0.84
				elif "arms" in piece.role: primary = v < 0.35 or (v > 0.5 and v < 0.82)
				elif "legs" in piece.role: primary = v > 0.48 or v < 0.24
				elif "core" in piece.role: primary = u < 0.28 or u > 0.72
				else: primary = fposmod(u*5+v*2,1) > 0.10
				var pigment := color if primary else Color("f4ecda")
				var painted_color := pigment*(0.45+value*0.65)
				if value > 0.9: painted_color = painted_color.lerp(Color("fff8e8"),(value-0.9)*3)
				bytes[index] = clampi(int(painted_color.r*255),0,255)
				bytes[index+1] = clampi(int(painted_color.g*255),0,255)
				bytes[index+2] = clampi(int(painted_color.b*255),0,255)
	var result := ImageTexture.create_from_image(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes))
	cache[key] = result
	return result

func worn(texture: Texture2D, condition: float) -> Texture2D:
	if condition >= 90: return texture
	var key := "wear"+str(texture.get_instance_id())+str(int(condition)/10)
	if cache.has(key): return cache[key]
	var image: Image = texture.get_image()
	if image.is_compressed(): image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var width := image.get_width()
	var threshold := int((90-condition)/9)
	for index in range(0,bytes.size(),4):
		if bytes[index+3] < 100: continue
		var x := (index/4)%width
		var y := (index/4)/width
		if mini(bytes[index],mini(bytes[index+1],bytes[index+2])) < 95: continue
		var scuff := (x*31+y*73)%181 < threshold or ((x/14+y/9*7)%53 == 0 and (x+y)%4 < 2)
		if scuff:
			bytes[index] = 91
			bytes[index+1] = 69
			bytes[index+2] = 48
	var result := ImageTexture.create_from_image(Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes))
	cache[key] = result
	return result

func exterior_lights(texture: Texture2D, lights: String, cutaway: bool) -> Texture2D:
	if lights == "lights_stock": return texture
	var key := "lamps"+str(texture.get_instance_id())+lights+str(cutaway)
	if cache.has(key): return cache[key]
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var width := image.get_width()
	var height := image.get_height()
	var color := Color("a38cc7" if lights == "lights_violet" else "70c9b8")
	for index in range(0,bytes.size(),4):
		if bytes[index+3] < 100: continue
		var x := (index/4)%width
		var y := (index/4)/width
		if x < width*0.39 and y > height*0.34 and y < height*0.65: continue
		if cutaway and y > height*0.40 and y < height*0.64 and x < width*0.87: continue
		if bytes[index+1] > 155 and bytes[index+2] > 155 and bytes[index] < bytes[index+1]*0.75:
			var intensity := maxf(bytes[index+1],bytes[index+2])/255.0
			bytes[index] = int(color.r*intensity*255)
			bytes[index+1] = int(color.g*intensity*255)
			bytes[index+2] = int(color.b*intensity*255)
	var result := ImageTexture.create_from_image(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes))
	cache[key] = result
	return result
