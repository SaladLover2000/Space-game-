extends RefCounted
## Composes original high-detail raster modules around real shoulder and hip anchors.
const ATLAS = preload("res://assets/art/robot-modules-v1.png")
const ATLAS_V2 = preload("res://assets/art/robot-modules-v2.png")
const WHITE_ATLAS = preload("res://assets/art/robot-modules-white-v1.png")
const WHITE_ATLAS_V2 = preload("res://assets/art/robot-modules-white-v2.png")
const SIDE_ATLAS = preload("res://assets/art/robot-modules-side-v2.png")
const PROFILE_HEADS = preload("res://assets/art/robot-profile-heads-v3.png")
const BACK_ATLAS = preload("res://assets/art/robot-modules-back-v1.png")
var decals := preload("res://assets/decal_art.gd").new()
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

func part_size(id: String, side: String = "source", angle: int = 0) -> Vector2:
	var region := source(id, side)
	if angle != 0:
		var r: Array = directional["back" if angle == 2 else "side"][id][side]
		region = Rect2(r[0],r[1],r[2],r[3])
	var height: float = HEIGHTS[id]
	return Vector2(region.size.x / region.size.y * height, height)

func pose(outfit: Dictionary, time: float = 0.0, mood: String = "idle", walking: bool = false, seated: bool = false, angle: int = 0, arm_targets: Dictionary = {}) -> Array:
	# Locomotion owns the gait; an inspection task cannot crouch a walking actor.
	if walking: mood = "idle"
	var body_id := resolve("robot_shell", outfit)
	var head_id := resolve("robot_visor", outfit)
	var arms_id := resolve("robot_arms", outfit)
	var legs_id := resolve("robot_legs", outfit)
	var core_id := resolve("robot_core", outfit)
	var body := part_size(body_id,"source",angle)
	var head := part_size(head_id,"source",angle)
	var leg := part_size(legs_id,"left",angle)
	var crouch := leg.y*0.10+absf(sin(time*6))*0.15 if walking else 1.8+sin(time*1.3)*0.15 if mood in ["inspecting","sealing","sorting"] else 0.0
	var body_top := -leg.y - body.y + 1.0+crouch
	var pieces: Array = []
	# Backpack is behind the body; front battery/beacon modules attach later.
	if core_id in ["robot_core_solar","robot_core_loader"]:
		var pack := part_size(core_id,"source",angle)
		pieces.append(piece(core_id,"source",Rect2(-pack.x/2,body_top-1,pack.x,pack.y)))
	for side in ["left", "right"]:
		var sign_side: float = -1.0 if side == "left" else 1.0
		var size := part_size(legs_id,side,angle)
		var lift := maxf(0.0,sin(time*12 + (0 if side == "left" else PI))) * 1.4 if walking else 0.0
		var stride := sin(time*12) * sign_side * 0.9 if walking else 0.0
		var x := sign_side * body.x * 0.22 - size.x/2 + stride
		if walking:
			var cycle := fposmod(time*1.4+(0.0 if side == "left" else 0.5),1.0)
			var stance := cycle < 0.6
			var stride_x := lerpf(1.8,-1.8,cycle/0.6) if stance else lerpf(-1.8,1.8,(cycle-0.6)/0.4)
			var lift_y := 0.0 if stance else sin((cycle-0.6)/0.4*PI)*1.8
			var hip := Vector2(sign_side*body.x*0.22,-leg.y+crouch)
			var shoe_h := size.y*0.16
			var foot := Vector2(sign_side*body.x*0.22+stride_x,-shoe_h-lift_y)
			var joint := solve_joint(hip,foot,size.y*0.48,size.y*0.36,1.0)
			var full := source(legs_id,side)
			var thigh := piece(legs_id,side,Rect2(hip-Vector2(size.x/2,0),Vector2(size.x,size.y*0.48)),joint.upper)
			thigh.source = Rect2(full.position,Vector2(full.size.x,full.size.y*0.48))
			thigh.segment = "thigh"
			pieces.append(thigh)
			var shin := piece(legs_id,side,Rect2(joint.joint-Vector2(size.x/2,0),Vector2(size.x,size.y*0.36)),joint.lower)
			shin.source = Rect2(full.position+Vector2(0,full.size.y*0.48),Vector2(full.size.x,full.size.y*0.36))
			shin.segment = "shin"
			pieces.append(shin)
			var shoe := piece(legs_id,side,Rect2(joint.end-Vector2(size.x/2,0),Vector2(size.x,shoe_h)))
			shoe.source = Rect2(full.position+Vector2(0,full.size.y*0.84),Vector2(full.size.x,full.size.y*0.16))
			shoe.segment = "shoe"
			shoe.stance = stance
			pieces.append(shoe)
		elif seated or mood in ["inspecting","sealing","sorting"]:
			var full_source := source(legs_id,side)
			var upper_height := size.y*(0.25 if seated and angle == 2 else 0.53)
			var upper_angle: float = -PI/2 if angle in [1,3] else (0.25 if side == "left" else -0.25)
			var hip := Vector2(x+size.x/2,-size.y+crouch)
			var lower_angle := 0.0
			if not seated:
				var foot := Vector2(x+size.x/2,0)
				var reach := hip.distance_to(foot)
				var lower_height := size.y-upper_height
				upper_angle = -acos(clampf((upper_height*upper_height+reach*reach-lower_height*lower_height)/(2*upper_height*reach),-1,1))
				var bend := hip+Vector2(0,upper_height).rotated(upper_angle)
				lower_angle = Vector2.DOWN.angle_to(foot-bend)
			var thigh := piece(legs_id,side,Rect2(hip-Vector2(size.x/2,0),Vector2(size.x,upper_height)),upper_angle)
			thigh.segment = "thigh"
			thigh.source = Rect2(full_source.position,Vector2(full_source.size.x,full_source.size.y*0.53))
			pieces.append(thigh)
			var knee := hip+Vector2(0,upper_height).rotated(upper_angle)
			var shin := piece(legs_id,side,Rect2(knee-Vector2(size.x/2,0.2),Vector2(size.x,size.y-upper_height+0.2)),lower_angle)
			shin.segment = "shin"
			shin.source = Rect2(full_source.position+Vector2(0,full_source.size.y*0.53),Vector2(full_source.size.x,full_source.size.y*0.47))
			pieces.append(shin)
		else:
			pieces.append(piece(legs_id,side,Rect2(x,-size.y-lift,size.x,size.y)))
	pieces.append(piece(body_id,"source",Rect2(-body.x/2,body_top,body.x,body.y)))
	for side in ["left", "right"]:
		var size := part_size(arms_id,side,angle)
		var x := -body.x/2-size.x+1.5 if side == "left" else body.x/2-1.5
		var rotation := sin(time*12) * (0.12 if side == "left" else -0.12) if walking else 0.0
		if seated:
			rotation = 0.55 if side == "left" else 0.75
		elif mood in ["working","typing","inspecting","sealing","sorting"]:
			rotation = 0.45+sin(time*1.6+(0 if side == "left" else 1))*0.10
		elif side == "right" and mood in ["happy","upgraded"]:
			rotation = -2.25 + sin(time*6)*0.12
		if mood in ["working","typing","inspecting","sealing","sorting"] or walking or seated:
			var full := source(arms_id,side)
			var phase: float = fposmod(time,8)
			var reach := sin(clampf((phase-1)/2,0,1)*PI/2) if phase < 6.8 else (8-phase)/1.2
			var upper_angle := -0.1-reach*0.5+sin(time*2)*0.07 if mood in ["working","typing","inspecting","sealing","sorting"] else rotation
			var elbow_angle := -0.2-reach*0.9+sin(time*2.1+(0 if side == "left" else 1))*0.15 if mood in ["working","typing","inspecting","sealing","sorting"] else 0.35+rotation*0.5
			if seated:
				upper_angle = -0.35 if side == "left" else 0.35
				elbow_angle = (2.1 if side == "left" else -2.1)+sin(time*2.4+(0 if side == "left" else 1))*0.12
			var wrist_target: Variant = arm_targets.get(side)
			if mood == "typing" and seated:
				wrist_target = Vector2((-1.0 if side == "left" else 1.0)*body.x*0.30,body_top+body.y*0.15+sin(time*8+(0 if side == "left" else PI))*0.25)
			if wrist_target is Vector2:
				var shoulder := Vector2(x+size.x/2,body_top+1.5)
				var joint := solve_joint(shoulder,wrist_target,size.y*0.43,size.y*0.37,-1.0 if side == "left" else 1.0)
				upper_angle = joint.upper
				elbow_angle = joint.lower
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
			var hand_angle := (-PI/2 if side == "left" else PI/2) if mood == "typing" and seated else elbow_angle+sin(time*2.7)*0.08
			var hand := piece(arms_id,side,Rect2(wrist-Vector2(size.x/2,0),Vector2(size.x,size.y*0.2)),hand_angle)
			hand.source = Rect2(full.position+Vector2(0,full.size.y*0.8),Vector2(full.size.x,full.size.y*0.2))
			hand.segment = "hand"
			pieces.append(hand)
		else: pieces.append(piece(arms_id,side,Rect2(x,body_top+1.5,size.x,size.y),rotation))

	var head_piece := piece(head_id,"source",Rect2(-head.x/2,body_top-head.y+1.0,head.x,head.y),0.0 if mood in ["sleeping","charging"] else 0.25+sin(time*1.5)*0.06 if mood == "inspecting" else 0.0)
	if mood == "inspecting": head_piece.pivot = Vector2(0,body_top+1)
	pieces.append(head_piece)
	if core_id not in ["robot_core_solar","robot_core_loader"]:
		var core := part_size(core_id,"source",angle)
		pieces.append(piece(core_id,"source",Rect2(-core.x/2,body_top+body.y*0.43-core.y/2,core.x,core.y)))
	if mood == "inspecting":
		var hip_pivot := Vector2(0,-leg.y+crouch)
		for part in pieces:
			if part.id != legs_id:
				part.parent_pivot = hip_pivot
				part.parent_rotation = 0.14+sin(time*1.3)*0.04 if angle in [1,3] else -0.18-sin(time*1.3)*0.10
	if mood == "inspecting" and not seated:
		# Rotated shoe rectangles have width: keep their visible soles on the floor.
		var floor_y := -INF
		for part in pieces:
			if part.id == legs_id:
				for point in vertices(part): floor_y = maxf(floor_y,point.y)
		for part in pieces:
			part.rect.position.y -= floor_y
			if part.has("pivot"): part.pivot.y -= floor_y
			if part.has("parent_pivot"): part.parent_pivot.y -= floor_y
	return pieces

func piece(id: String, side: String, destination: Rect2, rotation: float = 0.0) -> Dictionary:
	return {"id":id,"side":side,"source":source(id,side),"rect":destination,"rotation":rotation}

func vertices(piece_data: Dictionary) -> PackedVector2Array:
	var rect: Rect2 = piece_data.rect
	var pivot: Vector2 = piece_data.get("pivot",rect.position + Vector2(rect.size.x/2,0))
	var points := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for i in range(points.size()):
		points[i] = pivot + (points[i]-pivot).rotated(piece_data.rotation)
		if piece_data.has("parent_pivot"): points[i] = piece_data.parent_pivot+(points[i]-piece_data.parent_pivot).rotated(piece_data.parent_rotation)
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
	if angle != 0:
		if angle != 2 and id.begins_with("robot_visor"): return PROFILE_HEADS
		return BACK_ATLAS if angle == 2 else SIDE_ATLAS
	return WHITE_ATLAS_V2 if id.ends_with("_explorer") or id.ends_with("_loader") else WHITE_ATLAS

func finished_texture(id: String, outfit: Dictionary, angle: int = 0, mood: String = "idle") -> Texture2D:
	var selected := {}
	if angle == 0:
		for key in regions:
			if (key.ends_with("_explorer") or key.ends_with("_loader")) == (id.ends_with("_explorer") or id.ends_with("_loader")): selected[key] = regions[key]
	else: selected = directional["back" if angle == 2 else "side"]
	return emitter_texture(finish.worn(finish.painted(texture_for(id,angle),outfit.get("robot_paint","robot_paint_stock"),selected),maxf(current_state().get("robot_condition",100),current_state().get("robot_part_condition",{}).get(id,0))),id,mood,angle)

func finish_color(outfit: Dictionary) -> Color:
	return Color(PAINTS.get(outfit.get("robot_paint","robot_paint_stock"),"ffffff"))

func oriented_pose(outfit: Dictionary, time: float, mood: String, walking: bool, seated: bool, angle: int, arm_targets: Dictionary = {}) -> Array:
	var pieces := pose(outfit,time,mood,walking,seated,angle,arm_targets)
	if angle == 0: return pieces
	var view: Dictionary = directional["back" if angle == 2 else "side"]
	var body := part_size(resolve("robot_shell",outfit))
	for part in pieces:
		var data: Array = view[part.id][part.side]
		var original := source(part.id,part.side)
		var crop_start: float = (part.source.position.y-original.position.y)/original.size.y
		var crop_height: float = part.source.size.y/original.size.y
		part.source = Rect2(data[0],data[1]+data[3]*crop_start,data[2],data[3]*crop_height)
		if angle != 2 and part.id.begins_with("robot_core"):
			part.rect.position.x -= body.x*0.25
		part.rank = 5 if part.id.begins_with("robot_core") and angle == 2 else -1 if part.side == "left" and angle != 2 else 4 if part.side == "right" and angle != 2 else 1
	pieces.sort_custom(func(a,b): return a.rank < b.rank)
	return pieces

func draw(target: CanvasItem, feet: Vector2, time: float, mood: String, walking: bool = false, outfit: Dictionary = {}, seated: bool = false, angle: int = 0, arm_targets: Dictionary = {}) -> void:
	if walking: mood = "idle"
	var hop := absf(sin(time*2))*0.3 if mood in ["happy","upgraded"] and not seated else 0.0
	var origin := feet - Vector2(0,hop)
	var texture: Texture2D = texture_for("robot_shell_stock",angle)
	var atlas_size := Vector2(texture.get_size())
	for part in oriented_pose(outfit,time,mood,walking,seated,angle,arm_targets):
		var points := vertices(part)
		for i in range(points.size()):
			if angle == 3: points[i].x = -points[i].x
			points[i] += origin
		var src: Rect2 = part.source
		var uv := PackedVector2Array([src.position,Vector2(src.end.x,src.position.y),src.end,Vector2(src.position.x,src.end.y)])
		for i in range(uv.size()):
			uv[i] /= atlas_size
		var tint := Color.WHITE
		target.draw_polygon(points,PackedColorArray([tint]),uv,finished_texture(part.id,outfit,angle,mood))
	var torso := part_size(resolve("robot_shell",outfit),"source",angle)
	var leg_height := part_size(resolve("robot_legs",outfit),"left",angle).y
	decals.draw(target,Rect2(origin+Vector2(-torso.x*0.35,-leg_height-torso.y+4),Vector2(torso.x*0.28,4)))
	if not walking and not arm_targets.get("hide_tool",false) and mood in ["working","inspecting","sealing"] and (mood == "sealing" or work_action(time).holding_tool):
		var tool: Vector2 = tool_position(outfit,time,angle,seated,mood,arm_targets)
		if angle == 3: tool.x = -tool.x
		preload("res://assets/pixel_props.gd").new().draw_wrench(target,origin+tool,0.12*sin(time*3) if mood == "sealing" else -0.35)
	# Charging deliberately has no rising letters, sparkles or moving pixels.

static var emitter_cache: Dictionary = {}
func emitter_texture(texture: Texture2D, id: String, mood: String, angle: int = 0) -> Texture2D:
	var sleeping := mood in ["charging","sleeping"]
	var light: String = current_state().get("robot_light","cyan")
	var mode := "off" if sleeping else light
	if mood == "charging" and id.begins_with("robot_core"): mode = "orange"
	if mood == "charging" and id.begins_with("robot_shell"): mode = "sleep_shell"
	if mode == "cyan": return texture
	var key := str(texture.get_instance_id())+mode+(id+str(angle) if mode == "sleep_shell" or (sleeping and id.begins_with("robot_visor") and angle == 0) else "")
	if emitter_cache.has(key): return emitter_cache[key]
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var body_region := Rect2()
	if mode == "sleep_shell": body_region = source(id) if angle == 0 else Rect2(directional["back" if angle == 2 else "side"][id].source[0],directional["back" if angle == 2 else "side"][id].source[1],directional["back" if angle == 2 else "side"][id].source[2],directional["back" if angle == 2 else "side"][id].source[3])
	var optic_region := source(id) if id.begins_with("robot_visor") and angle == 0 else Rect2()
	var color := Color({"sleep_shell":"111d24","off":"111d24","orange":"ff9a32","blue":"459dff","green":"72df8b","violet":"bd8dff","white":"eff7ff"}.get(mode,"67e6ed"))
	for i in range(0,bytes.size(),4):
		if bytes[i+3] < 40: continue
		var r := bytes[i]/255.0
		var g := bytes[i+1]/255.0
		var b := bytes[i+2]/255.0
		var pixel := Vector2((i/4)%image.get_width(),(i/4)/image.get_width())
		var glint := false
		if sleeping and optic_region.has_area() and optic_region.has_point(pixel):
			var local := (pixel-optic_region.position)/optic_region.size
			glint = local.distance_to(Vector2(0.32,0.50)) < 0.12 or local.distance_to(Vector2(0.66,0.50)) < 0.12
			glint = glint and maxf(r,maxf(g,b)) > 0.65
		if glint or (g > r*1.25 and b > r*1.25 and g > 0.34 and b > 0.34):
			var emitter := color
			if mode == "sleep_shell" and body_region.has_point(pixel):
				var local := (pixel-body_region.position)/body_region.size
				if local.x > 0.30 and local.x < 0.70 and local.y > 0.18 and local.y < 0.78: emitter = Color("ff9a32")
			var shade := 0.60+maxf(g,b)*0.40
			bytes[i] = int(emitter.r*shade*255)
			bytes[i+1] = int(emitter.g*shade*255)
			bytes[i+2] = int(emitter.b*shade*255)
	var result := ImageTexture.create_from_image(Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes))
	emitter_cache[key] = result
	return result


func work_lamp_polygon(outfit: Dictionary, mood: String) -> PackedVector2Array:
	if mood not in ["working","inspecting"] or resolve("robot_visor",outfit) not in ["robot_visor_wide","robot_visor_amber","robot_visor_loader"]: return PackedVector2Array()
	var head_y := bounds(outfit).position.y+5
	return PackedVector2Array([Vector2(4,head_y),Vector2(23,head_y-3),Vector2(23,head_y+8)])

func work_action(time: float) -> Dictionary:
	var phase := fposmod(time,8)
	return {"phase":phase,"holding_tool":phase >= 2 and phase < 6.8,"description":"Collecting a tool" if phase < 2 else "Reconnecting and testing controls" if phase < 6.8 else "Returning the tool"}

func tool_position(outfit: Dictionary, time: float, angle: int = 0, seated: bool = false, mood: String = "working", arm_targets: Dictionary = {}) -> Vector2:
	for part in oriented_pose(outfit,time,mood,false,seated,angle,arm_targets):
		if part.get("segment","") == "hand" and part.side == "right":
			var rect: Rect2 = part.rect
			var point := rect.position+Vector2(rect.size.x/2,0)+Vector2(0,rect.size.y).rotated(part.rotation)
			if part.has("parent_pivot"): point = part.parent_pivot+(point-part.parent_pivot).rotated(part.parent_rotation)
			return point
	return Vector2(8,0)

func current_state() -> Dictionary:
	return Engine.get_main_loop().root.get_node("Game").state

func solve_joint(origin: Vector2, target: Vector2, upper_length: float, lower_length: float, bend: float) -> Dictionary:
	var offset := target-origin
	var reach := clampf(offset.length(),absf(upper_length-lower_length)+0.001,upper_length+lower_length-0.001)
	var endpoint := origin+offset.normalized()*reach
	var cosine := clampf((upper_length*upper_length+reach*reach-lower_length*lower_length)/(2*upper_length*reach),-1,1)
	var upper := Vector2.DOWN.angle_to(offset)-acos(cosine)*bend
	var joint := origin+Vector2.DOWN.rotated(upper)*upper_length
	return {"upper":upper,"lower":Vector2.DOWN.angle_to(endpoint-joint),"joint":joint,"end":endpoint}
