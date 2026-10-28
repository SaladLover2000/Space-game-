extends RefCounted
## Original articulated companion sprite; baseline is the soles of the feet.
var canvas: CanvasItem
var origin: Vector2
var equipment: Dictionary = {}

func box(x: float, y: float, w: float, h: float, color: String) -> void:
	canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2(w, h)), Color(tint(color)))

func plate(points: Array, color: String) -> void:
	var polygon := PackedVector2Array()
	for p in points:
		polygon.append(origin + Vector2(p[0], p[1]))
	canvas.draw_colored_polygon(polygon, Color(tint(color)))

func draw(target: CanvasItem, feet: Vector2, time: float, mood: String, walking: bool = false, outfit: Dictionary = {}) -> void:
	equipment = outfit
	canvas = target
	var excited := mood in ["happy", "upgraded"]
	var hop := floorf(abs(sin(time * 7)) * 2) if excited else 0.0
	origin = feet + Vector2(0, -hop)
	if walking:
		origin.y -= floorf(abs(sin(time * 12)))
	var stride := floorf(sin(time * 12) * 2) if walking else 0.0
	# Feet, articulated legs and the hip linkage retain distinct silhouettes.
	box(-8 + stride, -2, 7, 3, "142a3d")
	box(2 - stride, -2, 7, 3, "142a3d")
	box(-7 + stride, -3, 6, 3, "a6b9ba")
	box(2 - stride, -3, 6, 3, "a6b9ba")
	box(-7 + stride, -2, 2, 1, "d1d7c7")
	box(6 - stride, -2, 2, 1, "d1d7c7")
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

	origin -= Vector2(-slouch, slouch)
	draw_equipment(time)

func tint(color: String) -> String:
	var shell: String = equipment.get("robot_shell", "robot_shell_stock")
	var palette := {}
	if shell == "robot_shell_copper":
		palette = {"9bb2b7":"b47759", "b3c4c3":"d8aa7c", "d0d6c5":"f2dcaf", "98aeb2":"c68d69", "617c8c":"795253", "a6b9ba":"b98469"}
	elif shell == "robot_shell_cobalt":
		palette = {"9bb2b7":"4777b0", "b3c4c3":"719fcb", "d0d6c5":"c5d9e5", "98aeb2":"5688bc", "617c8c":"365c8e", "a6b9ba":"638cbd"}
	return palette.get(color, color)

func draw_equipment(time: float) -> void:
	# Draw after the head, restoring the feet origin so all parts align.
	match equipment.get("robot_visor", ""):
		"robot_visor_wide":
			box(-6,-32,12,5,"102939")
			box(-5,-31,10,2,"64eadf")
			box(-5 + fmod(time * 4, 8),-31,2,2,"d2fff1")
		"robot_visor_amber":
			box(-7,-34,14,2,"4e5968")
			for x in [-5, 2]:
				box(x,-32,4,4,"f1b76d")
				box(x+1,-31,2,2,"fff0b2")
	match equipment.get("robot_arms", ""):
		"robot_arms_utility", "robot_arms_precision":
			var precision: bool = equipment.robot_arms == "robot_arms_precision"
			for x in [-12, 8]:
				box(x,-23,5,5,"d7d8c5" if precision else "bd916c")
				box(x+1,-22,3,1,"8aeee0")
				box(x,-14,5,5,"a1c3cd" if precision else "6d8292")
				box(x+1,-13,1,3,"e0e7d2")
				box(x,-9,1,3,"afc8c6")
				box(x+4,-9,1,3,"afc8c6")
	match equipment.get("robot_legs", ""):
		"robot_legs_boots", "robot_legs_strider":
			for x in [-8, 2]:
				box(x,-4,8,5,"344e62")
				box(x+1,-3,6,2,"9db9bf")
				box(x+1,0,6,1,"77e1cf")
				if equipment.robot_legs == "robot_legs_strider":
					box(x,-11,2,8,"c3c9bb")
	match equipment.get("robot_core", ""):
		"robot_core_beacon":
			box(-4,-20,9,7,"1a3348")
			canvas.draw_arc(origin + Vector2(0,-17), 2.7, 0, TAU, 16, Color("7af1db"), 1)
			box(-1,-18,2,2,"d5fff1")
		"robot_core_solar":
			for x in [-15, 12]:
				box(x,-29,4,12,"142c43")
				for y in range(-28,-18,3):
					box(x+1,y,2,2,"658ed0")
			box(-3,-20,6,5,"e6b774")
			box(-2,-19,4,1,"fff1b7")
