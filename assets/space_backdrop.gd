extends RefCounted
## Original seeded pixel scenery. These fly-bys are decorative, not discoveries.
var service := preload("res://assets/service_art.gd").new()
var nebula: ImageTexture
var planets: Array[ImageTexture] = []
const PALETTES = [
	["291b47", "643359", "bd4f64", "f48c57", "ffd27d"],
	["132d53", "19526d", "208eaa", "58daca", "b8f2a1"],
	["211d51", "45336d", "9154a5", "dc7dba", "ffd1a1"]
]

func _init() -> void:
	var image := Image.create(280, 150, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 82471
	noise.frequency = 0.027
	noise.fractal_octaves = 4
	for y in range(150):
		for x in range(280):
			var field := noise.get_noise_2d(x, y)
			var ribbon := sin(x * 0.018 + y * 0.025) * 0.22 + field
			var color := Color("030611")
			if ribbon > -0.2:
				color = Color("070d1c")
			if ribbon > 0.0:
				color = Color("0a1328")
			if ribbon > 0.19:
				color = Color("111a31")
			if ribbon > 0.31:
				color = Color("1b1a36")
			if field > 0.28 and x < 165:
				color = Color("10232d")
			if field > 0.4 and x < 165:
				color = Color("19303a")
			if (x * 73 + y * 31) % 7 == 0:
				color = color.lightened(0.07)
			image.set_pixel(x, y, color)
	nebula = ImageTexture.create_from_image(image)
	for index in range(3):
		planets.append(make_planet(index))

func make_planet(index: int) -> ImageTexture:
	var image := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var palette: Array = PALETTES[index]
	for y in range(80):
		for x in range(80):
			var p := (Vector2(x, y) - Vector2(39.5, 39.5)) / 39.0
			if p.length_squared() > 1.0:
				continue
			var z := sqrt(1.0 - p.length_squared())
			var light := Vector3(p.x, p.y, z).dot(Vector3(-0.6, -0.65, 0.6).normalized())
			var bands := sin(y * 0.29 + x * 0.12 + sin(x * 0.21) * 1.5)
			var fleck := float((x * 37 + y * 71 + index * 13) % 17) / 17.0
			var tone := clampi(int(light * 3.0 + 1.2 + bands * 0.65 + fleck * 0.55), 0, 4)
			image.set_pixel(x, y, Color(palette[tone]))
	return ImageTexture.create_from_image(image)

func planet_position(index: int, time: float) -> Vector2:
	var origins := [Vector2(218, 38), Vector2(38, 23), Vector2(100, 132)]
	var speeds := [0.7, 1.25, 0.45]
	return Vector2(fposmod(origins[index].x + time * speeds[index] + 45, 370) - 45, origins[index].y + sin(time * 0.035 + index) * 2)

func draw(canvas: CanvasItem, time: float, width: float = 280.0) -> void:
	canvas.draw_texture_rect(nebula, Rect2(0, 0, width, 150), false)
	for i in range(145):
		var layer := i % 3
		var x := floorf(fposmod(i * 67.31 + time * (0.25 + layer * 0.5), width))
		var y := floorf(fposmod(i * 31.71, 150))
		var colors := [Color("566fa2"), Color("64c4d1"), Color("f7d68b")]
		canvas.draw_rect(Rect2(x, y, 1, 1), colors[layer])
		if i % 19 == 0:
			canvas.draw_rect(Rect2(x - 1, y, 3, 1), colors[layer])
			canvas.draw_rect(Rect2(x, y - 1, 1, 3), colors[layer])
	var radii := [35.0, 14.0, 10.0]
	for i in range(3):
		var center := planet_position(i, time)
		center.x *= width / 280.0
		var radius: float = radii[i]
		if i == 2:
			canvas.draw_arc(center, radius * 1.6, 0, PI, 24, Color("b390cb"), 1)
		canvas.draw_texture_rect(planets[i], Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), false)
		if i == 2:
			canvas.draw_arc(center, radius * 1.6, PI, TAU, 24, Color("efbbd8"), 1)

func draw_world(canvas: CanvasItem, time: float, camera: Rect2) -> void:
	canvas.draw_rect(camera.grow(10),Color("030611"))
	# One very distant cloud field, not repeated patches of bright nebula.
	canvas.draw_texture_rect(nebula,Rect2(-800,-600,1800,1200),false,Color(0.8,0.85,1,0.6))
	for tile_y in range(floori(camera.position.y/240)-1,ceili(camera.end.y/240)+1):
		for tile_x in range(floori(camera.position.x/420)-1,ceili(camera.end.x/420)+1):
			for i in range(45):
				var seed_value: float = i*67.31+tile_y*23.7+tile_x*17.1
				var speed: float = 2.0+(i%3)*2.0
				var position := Vector2(tile_x*420+fposmod(seed_value+time*speed,420),tile_y*240+fposmod(i*31.71+tile_x*11,240))
				var color := Color("6b7e96" if i%3 else "b1c5d5")
				canvas.draw_line(position,position+Vector2((0.7+i%3*0.4)*(2.5 if Game.state.flight_mode == "burn" else 1.5 if Game.state.flight_mode == "cruise" else 1),0),color,0.5)
	var station_phase := fposmod(time,240)
	if station_phase > 120: service.draw(canvas,"station",Rect2(Vector2(420-(station_phase-120)*3,-20),Vector2(60,46)))
	var radii := [70.0,26.0,17.0]
	for i in range(3):
		var center := cruise_planet_position(i,time)
		canvas.draw_texture_rect(planets[i],Rect2(center-Vector2.ONE*radii[i],Vector2.ONE*radii[i]*2),false)

func cruise_planet_position(index: int, time: float) -> Vector2:
	return Vector2(preload("res://scripts/contact_geometry.gd").planet_x(index,time),[-25.0,180.0,70.0][index])
