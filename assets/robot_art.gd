extends RefCounted
## Composes original high-detail raster modules around real shoulder and hip anchors.
const ATLAS = preload("res://assets/art/robot-modules-v1.png")
const ATLAS_V2 = preload("res://assets/art/robot-modules-v2.png")
const WHITE_ATLAS = preload("res://assets/art/robot-modules-white-v1.png")
const WHITE_ATLAS_V2 = preload("res://assets/art/robot-modules-white-v2.png")
const SIDE_ATLAS = preload("res://assets/art/robot-modules-side-v1.png")
const BACK_ATLAS = preload("res://assets/art/robot-modules-back-v1.png")
var finish := preload("res://assets/material_finish.gd").new()
var directional: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/robot_directional_atlas.json"))
static var neutral_atlases: Dictionary = {}
const PAINTS = {"robot_paint_stock":"fff3dc","robot_paint_sand":"dcc9a5","robot_paint_cobalt":"92b6ea","robot_paint_sage":"9bc8ad","robot_paint_crimson":"df969b","robot_paint_gold":"e5c685"}
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/robot_atlas.json"))
const HEIGHTS = {
	"robot_shell_stock":14.0, "robot_shell_copper":17.0, "robot_shell_cobalt":18.0,
	"robot_visor_stock":10.0, "robot_visor_wide":10.5, "robot_visor_amber":12.0,
	"robot_arms_stock":14.0, "robot_arms_utility":16.0, "robot_arms_precision":17.0,
	"robot_legs_stock":11.0, "robot_legs_boots":10.0, "robot_legs_strider":15.0,
	"robot_visor_explorer":10.0,"robot_shell_explorer":16.0,"robot_arms_explorer":15.0,"robot_legs_explorer":12.0,"robot_core_explorer":5.0,
	"robot_visor_loader":11.0,"robot_shell_loader":20.0,"robot_arms_loader":19.0,"robot_legs_loader":14.0,"robot_core_loader":18.0,
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
	if core_id in ["robot_core_solar","robot_core_loader"]:
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
		elif mood in ["working","typing"]:
			rotation = 0.45+sin(time*1.6+(0 if side == "left" else 1))*0.10
		elif side == "right" and mood in ["happy","upgraded"]:
			rotation = -2.25 + sin(time*6)*0.12
		if mood in ["working","typing"] or walking or seated:
			var full := source(arms_id,side)
			var phase: float = fposmod(time,8)
			var reach := sin(clampf((phase-1)/2,0,1)*PI/2) if phase < 6.8 else (8-phase)/1.2
			var upper_angle := -0.1-reach*0.5+sin(time*2)*0.07 if mood in ["working","typing"] else rotation
			var elbow_angle := -0.2-reach*0.9+sin(time*2.1+(0 if side == "left" else 1))*0.15 if mood in ["working","typing"] else 0.35+rotation*0.5
			if seated:
				upper_angle = -0.35 if side == "left" else 0.35
				elbow_angle = (2.1 if side == "left" else -2.1)+sin(time*2.4+(0 if side == "left" else 1))*0.12
			var upper := piece(arms_id,side,Rect2(x,body_top+1.5,size.x,size.y*0.43),upper_angle)
			upper.source = Rect2(full.position,Vector2(full.size.x,full.size.y*0.43))
			upper.segment = "upper_arm"
			pieces.append(upper)
			var elbow := Vector2(x+size.x/2,body_top+1.5)+Vector2(0,size.y*0.43).rotated(upper_angle)
			var fore := piece(arms_id,side,Rect2(elbow-Vector2(size.x/2,0),Vector2(size.x,size.y*0.37)),elbow_angle)
			fore.source = Rect2(full.position+Vector2(0,full.size.y*0.43),Vector2(full.size.x,full.size.y*0.37))
			fore.segment = "forearm"
			pieces.append(fore)
			var wrist := elbow+Vector2(0,size.y*0.37).rotated(elbow_angle)
			var hand := piece(arms_id,side,Rect2(wrist-Vector2(size.x/2,0),Vector2(size.x,size.y*0.2)),elbow_angle+sin(time*2.7)*0.18)
			hand.source = Rect2(full.position+Vector2(0,full.size.y*0.8),Vector2(full.size.x,full.size.y*0.2))
			hand.segment = "hand"
			pieces.append(hand)
		else: pieces.append(piece(arms_id,side,Rect2(x,body_top+1.5,size.x,size.y),rotation))

	pieces.append(piece(head_id,"source",Rect2(-head.x/2,body_top-head.y+1.0,head.x,head.y),0.16 if mood == "sleeping" else 0.0))
	if core_id not in ["robot_core_solar","robot_core_loader"]:
		var core := part_size(core_id)
		pieces.append(piece(core_id,"source",Rect2(-core.x/2,body_top+body.y*0.43-core.y/2,core.x,core.y)))
	return pieces

func piece(id: String, side: String, destination: Rect2, rotation: float = 0.0) -> Dictionary:
	return {"id":id,"side":side,"source":source(id,side),"rect":destination,"rotation":rotation}

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
	return "Your build / %.2fx original height  /  %.2fx original width" % [size.y/original.y,size.x/original.x]

func texture_for(id: String, angle: int = 0) -> Texture2D:
	if angle != 0: return BACK_ATLAS if angle == 2 else SIDE_ATLAS
	return WHITE_ATLAS_V2 if id.ends_with("_explorer") or id.ends_with("_loader") else WHITE_ATLAS

func finished_texture(id: String, outfit: Dictionary, angle: int = 0) -> Texture2D:
	var selected := {}
	if angle == 0:
		for key in regions:
			if (key.ends_with("_explorer") or key.ends_with("_loader")) == (id.ends_with("_explorer") or id.ends_with("_loader")): selected[key] = regions[key]
	else: selected = directional["back" if angle == 2 else "side"]
	return finish.painted(texture_for(id,angle),outfit.get("robot_paint","robot_paint_stock"),selected)

func finish_color(outfit: Dictionary) -> Color:
	return Color(PAINTS.get(outfit.get("robot_paint","robot_paint_stock"),"ffffff"))

func oriented_pose(outfit: Dictionary, time: float, mood: String, walking: bool, seated: bool, angle: int) -> Array:
	var pieces := pose(outfit,time,mood,walking,seated)
	if angle == 0: return pieces
	var view: Dictionary = directional["back" if angle == 2 else "side"]
	var body := part_size(resolve("robot_shell",outfit))
	for part in pieces:
		var data: Array = view[part.id][part.side]
		var original := source(part.id,part.side)
		var crop_start: float = (part.source.position.y-original.position.y)/original.size.y
		var crop_height: float = part.source.size.y/original.size.y
		part.source = Rect2(data[0],data[1]+data[3]*crop_start,data[2],data[3]*crop_height)
		var rect: Rect2 = part.rect
		var width: float = part.source.size.x/part.source.size.y*rect.size.y
		var center := rect.get_center().x
		if angle != 2:
			center = (body.x*0.08 if part.side == "right" else -body.x*0.08) if part.id.begins_with("robot_arms") or part.id.begins_with("robot_legs") else -body.x*0.35 if part.id.begins_with("robot_core") else 0.0
		part.rect = Rect2(center-width/2,rect.position.y,width,rect.size.y)
		part.rank = 5 if part.id.begins_with("robot_core") and angle == 2 else -1 if part.side == "left" and angle != 2 else 4 if part.side == "right" and angle != 2 else 1
	pieces.sort_custom(func(a,b): return a.rank < b.rank)
	return pieces

func draw(target: CanvasItem, feet: Vector2, time: float, mood: String, walking: bool = false, outfit: Dictionary = {}, seated: bool = false, angle: int = 0) -> void:
	var hop := absf(sin(time*2))*0.3 if mood in ["happy","upgraded"] and not seated else 0.0
	var origin := feet - Vector2(0,hop)
	var texture: Texture2D = texture_for("robot_shell_stock",angle)
	var atlas_size := Vector2(texture.get_size())
	var lamp := work_lamp_polygon(outfit,mood)
	if not lamp.is_empty() and angle != 2:
		for index in range(lamp.size()): lamp[index] += origin
		target.draw_colored_polygon(lamp,Color(1,0.96,0.8,0.09))
	for part in oriented_pose(outfit,time,mood,walking,seated,angle):
		var points := vertices(part)
		for i in range(points.size()):
			if angle == 3: points[i].x = -points[i].x
			points[i] += origin
		var src: Rect2 = part.source
		var uv := PackedVector2Array([src.position,Vector2(src.end.x,src.position.y),src.end,Vector2(src.position.x,src.end.y)])
		for i in range(uv.size()):
			uv[i] /= atlas_size
		var tint := Color.WHITE
		target.draw_polygon(points,PackedColorArray([tint]),uv,finished_texture(part.id,outfit,angle))
	if mood == "working":
		var tool: Vector2 = tool_position(outfit,time,angle,seated) if work_action(time).holding_tool else Vector2(8,-1)
		if angle == 3: tool.x = -tool.x
		tool += origin
		target.draw_line(tool,tool+Vector2(3,-4).rotated(sin(time*2)*0.2),Color("26333b"),1.5)
		target.draw_line(tool,tool+Vector2(3,-4).rotated(sin(time*2)*0.2),Color("d2b47b"),0.65)
		target.draw_arc(tool+Vector2(3,-4),0.8,0.3,4.8,5,Color("bec7c5"),0.6)
	if mood == "charging":
		var right_edge := bounds(outfit).end.x
		for i in range(3):
			target.draw_rect(Rect2(origin + Vector2(right_edge+2,-8-i*4),Vector2(0.7,1.5)),Color("8ae9d8"))


func work_lamp_polygon(outfit: Dictionary, mood: String) -> PackedVector2Array:
	if mood != "working" or resolve("robot_visor",outfit) not in ["robot_visor_wide","robot_visor_amber","robot_visor_loader"]: return PackedVector2Array()
	var head_y := bounds(outfit).position.y+5
	return PackedVector2Array([Vector2(4,head_y),Vector2(23,head_y-3),Vector2(23,head_y+8)])

func work_action(time: float) -> Dictionary:
	var phase := fposmod(time,8)
	return {"phase":phase,"holding_tool":phase >= 2 and phase < 6.8,"description":"Collecting a tool" if phase < 2 else "Reconnecting and testing controls" if phase < 6.8 else "Returning the tool"}

func tool_position(outfit: Dictionary, time: float, angle: int = 0, seated: bool = false) -> Vector2:
	for part in oriented_pose(outfit,time,"working",false,seated,angle):
		if part.get("segment","") == "hand" and part.side == "right":
			var rect: Rect2 = part.rect
			return rect.position+Vector2(rect.size.x/2,0)+Vector2(0,rect.size.y).rotated(part.rotation)
	return Vector2(8,0)

