extends RefCounted
## Original articulated companion sprite; baseline is the soles of the feet.
var canvas: CanvasItem
var origin: Vector2

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2(w, h)), Color(color))

func plate(points: Array, color: String) -> void:
	var polygon := PackedVector2Array()
	for p in points:
		polygon.append(origin + Vector2(p[0], p[1]))
	canvas.draw_colored_polygon(polygon, Color(color))

func draw(target: CanvasItem, feet: Vector2, time: float, mood: String) -> void:
	canvas = target
	var excited := mood in ["happy", "upgraded"]
	var hop := floorf(abs(sin(time * 7)) * 2) if excited else 0.0
	origin = feet + Vector2(0, -hop)
	# Feet, articulated legs and the hip linkage retain distinct silhouettes.
	box(-8, -2, 7, 3, "142a3d")
	box(2, -2, 7, 3, "142a3d")
	box(-7, -3, 6, 3, "a6b9ba")
	box(2, -3, 6, 3, "a6b9ba")
	box(-7, -2, 2, 1, "d1d7c7")
	box(6, -2, 2, 1, "d1d7c7")
	for x in [-5, 3]:
		box(x, -9, 3, 6, "263e52")
		box(x + 1, -8, 1, 4, "a4b7b7")
		box(x, -10, 3, 3, "617c8c")
		box(x + 1, -10, 1, 1, "c1cbbf")
	box(-5, -12, 11, 3, "283e51")
	box(-3, -12, 7, 2, "8b9fa4")
	# Tapered breastplate and waist, recessed battery indicator and side vents.
	plate([[-7,-23],[6,-23],[9,-20],[6,-12],[-4,-12],[-8,-18]], "172c40")
	plate([[-5,-22],[5,-22],[7,-19],[4,-13],[-3,-13],[-6,-18]], "9bb2b7")
	box(-4, -21, 9, 2, "d0d6c5")
	box(-4, -18, 8, 4, "30495a")
	box(-3, -17, 2, 2, "f2c67d" if mood == "sad" else "8ce9ce")
	box(0, -17, 3, 1, "76b5b6" if mood == "charging" else "627f8c")
	box(5, -19, 1, 4, "546d80")
	box(-5, -15, 2, 1, "677f89")
	# Shoulder joints, upper arms, elbow pins, forearms and two-finger grippers.
	for side in [-1, 1]:
		var raised: bool = side == 1 and excited
		var x: int = -11 if side == -1 else 8
		box(x, -22, 4, 4, "344f62")
		box(x + 1, -22, 2, 2, "bfd0c8")
		var elbow_y := -27 if raised else -17
		box(x + 1, -25 if raised else -18, 2, 5, "708c99")
		box(x, elbow_y, 4, 3, "2e475d")
		box(x + 1, elbow_y, 2, 1, "d5ccb0")
		var wrist_y := -31 if raised else -14
		box(x, wrist_y, 4, 4, "98aeb2")
		box(x + 1, wrist_y, 1, 3, "c8d2c5")
		var fingers_y := wrist_y - 2 if raised else wrist_y + 4
		box(x, fingers_y, 1, 2, "b6c8c2")
		box(x + 3, fingers_y, 1, 2, "b6c8c2")
	# Neck spindle and chamfered helmet keep the head separate from the torso.
	box(-2, -25, 4, 3, "5e7b8b")
	var slouch := 1 if mood == "sad" else 0
	origin += Vector2(-slouch, slouch)
	plate([[-6,-36],[5,-36],[8,-33],[8,-27],[5,-25],[-6,-25],[-8,-28],[-8,-33]], "182d42")
	plate([[-5,-35],[4,-35],[7,-32],[7,-28],[4,-26],[-5,-26],[-7,-29],[-7,-32]], "b3c4c3")
	box(-4, -35, 8, 1, "e1e2ca")
	box(-6, -32, 12, 5, "142e43")
	box(-8, -31, 2, 3, "748e9e")
	box(7, -31, 2, 3, "748e9e")
	box(7, -30, 1, 1, "e3b979")
	var blink := fmod(time, 4.7) > 4.5
	var eye := "719eab" if mood == "sad" else "80ead8"
	box(-4, -31, 3, 1 if blink or mood == "sad" else 3, eye)
	box(2, -31, 3, 1 if blink or mood == "sad" else 3, eye)
	if excited:
		box(-3, -32, 1, 1, eye)
		box(3, -32, 1, 1, eye)
	box(-1, -27, 2, 1, "536e7f")
	box(1, -39, 1, 4, "87a8b1")
	box(0, -40, 3, 2, "f0c97f")
	if mood == "charging":
		for i in range(3):
			box(12, -13 - i * 5 - floorf(fmod(time * 3, 4)), 1, 2, "8fe4cf")
	if excited:
		box(14, -32, 1, 5, "f6d58c")
		box(12, -30, 5, 1, "f6d58c")
