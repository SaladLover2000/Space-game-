extends RefCounted
## Composes original high-detail raster modules around real shoulder and hip anchors.
const ATLAS = preload("res://assets/art/robot-modules-v1.png")
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/robot_atlas.json"))
const HEIGHTS = {
	"robot_shell_stock":14.0, "robot_shell_copper":17.0, "robot_shell_cobalt":18.0,
	"robot_visor_stock":10.0, "robot_visor_wide":10.5, "robot_visor_amber":12.0,
	"robot_arms_stock":14.0, "robot_arms_utility":16.0, "robot_arms_precision":17.0,
	"robot_legs_stock":11.0, "robot_legs_boots":10.0, "robot_legs_strider":15.0,
	"robot_core_stock":5.0, "robot_core_beacon":7.0, "robot_core_solar":17.0
}

func resolve(slot: String, outfit: Dictionary) -> String:
	var id: String = outfit.get(slot, slot + "_stock")
	return id if regions.has(id) and id.begins_with(slot + "_") else slot + "_stock"

func source(id: String, side: String = "source") -> Rect2:
	var value: Array = regions[id][side]
	return Rect2(value[0], value[1], value[2], value[3])

func part_size(id: String, side: String = "source") -> Vector2:
	var region := source(id, side)
	var height: float = HEIGHTS[id]
	return Vector2(region.size.x / region.size.y * height, height)

func pose(outfit: Dictionary, time: float = 0.0, mood: String = "idle", walking: bool = false, seated: bool = false) -> Array:
	var body_id := resolve("robot_shell", outfit)
	var head_id := resolve("robot_visor", outfit)
	var arms_id := resolve("robot_arms", outfit)
	var legs_id := resolve("robot_legs", outfit)
	var core_id := resolve("robot_core", outfit)
	var body := part_size(body_id)
	var head := part_size(head_id)
	var leg := part_size(legs_id, "left")
	var body_top := -leg.y - body.y + 1.0
	var pieces: Array = []
	# Backpack is behind the body; front battery/beacon modules attach later.
	if core_id == "robot_core_solar":
		var pack := part_size(core_id)
		pieces.append(piece(core_id,"source",Rect2(-pack.x/2,body_top-1,pack.x,pack.y)))
	for side in ["left", "right"]:
		var sign_side: float = -1.0 if side == "left" else 1.0
		var size := part_size(legs_id, side)
		var lift := maxf(0.0,sin(time*12 + (0 if side == "left" else PI))) * 1.4 if walking else 0.0
		var stride := sin(time*12) * sign_side * 0.9 if walking else 0.0
		var x := sign_side * body.x * 0.22 - size.x/2 + stride
		if seated:
			var full_source := source(legs_id,side)
			var upper_height := size.y*0.53
			var angle := 1.15
			var thigh := piece(legs_id,side,Rect2(x,-size.y,size.x,upper_height),angle)
			thigh.source = Rect2(full_source.position,Vector2(full_source.size.x,full_source.size.y*0.53))
			pieces.append(thigh)
			var knee := Vector2(x+size.x/2,-size.y)+Vector2(0,upper_height).rotated(angle)
			var shin := piece(legs_id,side,Rect2(knee-Vector2(size.x/2,0.2),Vector2(size.x,size.y-upper_height+0.2)),-0.08)
			shin.source = Rect2(full_source.position+Vector2(0,full_source.size.y*0.53),Vector2(full_source.size.x,full_source.size.y*0.47))
			pieces.append(shin)
		else:
			pieces.append(piece(legs_id,side,Rect2(x,-size.y-lift,size.x,size.y)))
	pieces.append(piece(body_id,"source",Rect2(-body.x/2,body_top,body.x,body.y)))
	for side in ["left", "right"]:
		var size := part_size(arms_id, side)
		var x := -body.x/2-size.x+1.5 if side == "left" else body.x/2-1.5
		var rotation := sin(time*12) * (0.12 if side == "left" else -0.12) if walking else 0.0
		if seated:
			rotation = 0.55 if side == "left" else 0.75
		elif side == "right" and mood in ["happy","upgraded"]:
			rotation = -2.25 + sin(time*6)*0.12
		pieces.append(piece(arms_id,side,Rect2(x,body_top+1.5,size.x,size.y),rotation))
	pieces.append(piece(head_id,"source",Rect2(-head.x/2,body_top-head.y+1.0,head.x,head.y)))
	if core_id != "robot_core_solar":
		var core := part_size(core_id)
		pieces.append(piece(core_id,"source",Rect2(-core.x/2,body_top+body.y*0.43-core.y/2,core.x,core.y)))
	return pieces

func piece(id: String, side: String, destination: Rect2, rotation: float = 0.0) -> Dictionary:
	return {"id":id,"source":source(id,side),"rect":destination,"rotation":rotation}

func vertices(piece_data: Dictionary) -> PackedVector2Array:
	var rect: Rect2 = piece_data.rect
	var pivot := rect.position + Vector2(rect.size.x/2,0)
	var points := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for i in range(points.size()):
		points[i] = pivot + (points[i]-pivot).rotated(piece_data.rotation)
	return points

func bounds(outfit: Dictionary, time: float = 0.0, mood: String = "idle", walking: bool = false, seated: bool = false) -> Rect2:
	var initialized := false
	var result := Rect2()
	for part in pose(outfit,time,mood,walking,seated):
		for point in vertices(part):
			if not initialized:
				result = Rect2(point,Vector2.ZERO)
				initialized = true
			else:
				result = result.expand(point)
	return result

func clearance(outfit: Dictionary) -> float:
	var box := bounds(outfit)
	return maxf(10.0,maxf(absf(box.position.x),absf(box.end.x))+1.0)

func build_description(outfit: Dictionary) -> String:
	var size := bounds(outfit).size
	var original := bounds({}).size
	return "Your build / %.2f× original height · %.2f× original width" % [size.y/original.y,size.x/original.x]

func draw(target: CanvasItem, feet: Vector2, time: float, mood: String, walking: bool = false, outfit: Dictionary = {}, seated: bool = false) -> void:
	var hop := absf(sin(time*7))*1.5 if mood in ["happy","upgraded"] and not seated else 0.0
	var origin := feet - Vector2(0,hop)
	var atlas_size := Vector2(ATLAS.get_size())
	for part in pose(outfit,time,mood,walking,seated):
		var points := vertices(part)
		for i in range(points.size()):
			points[i] += origin
		var src: Rect2 = part.source
		var uv := PackedVector2Array([src.position,Vector2(src.end.x,src.position.y),src.end,Vector2(src.position.x,src.end.y)])
		for i in range(uv.size()):
			uv[i] /= atlas_size
		var tint := Color(0.74,0.82,0.88) if mood == "sad" else Color.WHITE
		target.draw_polygon(points,PackedColorArray([tint]),uv,ATLAS)
	if mood == "charging":
		var right_edge := bounds(outfit).end.x
		for i in range(3):
			target.draw_rect(Rect2(origin + Vector2(right_edge+2,-8-i*4-fposmod(time*3,3)),Vector2(0.7,1.5)),Color("8ae9d8"))
