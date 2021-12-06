extends Node2D

const SLICE_EXPLODE_FORCE : float = 1000.0
const MIN_AREA_FOR_SHAPE : float = 100.0

# NOTE: if player falls below this size, they die
const PLAYER_MIN_AREA_FOR_SHAPE : float = 1250.0
const PLAYER_MIN_AREA_GENERAL : float = 1000.0

var player_part_scene = preload("res://scenes/player_part.tscn")

onready var main_node = get_parent()
onready var dramatic_slice = get_node("../DramaticSlice")
onready var map = get_node("../Map")
onready var shape_manager = get_node("../ShapeManager")
onready var mode = get_node("../ModeManager")
onready var particles = get_node("../Particles")

var start_point
var end_point

# Actual slicing functionality
func slice_bodies_hitting_line(p1 : Vector2, p2 : Vector2, exclude = [], include = [], attacking_throwable = null):
	# create a (narrow, elongated) rectangle along line
	var angle = (p2 - p1).angle()
	var avg_pos = (p2 + p1)*0.5
	
	var shape = RectangleShape2D.new()
	shape.extents.x = 0.5*(p2-p1).length()
	shape.extents.y = 5
	
	# check what it hits
	var physics = get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	query.set_shape(shape)
	query.transform = Transform2D(angle, avg_pos)

	# filter anything we don't (or do) want
	var results = physics.intersect_shape(query)
	var bodies = []
	for res in results:
		var body = res.collider
		
		if not body.is_in_group("Sliceables"): continue
		if body in exclude: continue
		if include.size() > 0 and not (body in include): continue
		if body in bodies: continue
		
		bodies.append(body)
	
	if bodies.size() <= 0: return []

	# finally, slice whatever is left
	var final_bodies = []
	for b in bodies:
		final_bodies += slice_body(b, p1, p2, attacking_throwable)
	
	return final_bodies

func slice_body(b, p1, p2, attacking_throwable):
	var original_player_num = -1
	var original_color = Color(1,1,1)
	var use_multi_color = true
	var make_collectible = false
	
	if b.modules.has("status"):
		original_player_num = b.modules.status.player_num
	
	if b.modules.has("drawer"):
		original_color = b.modules.drawer.color
		use_multi_color = b.modules.drawer.use_multi_color
	
	if b.get("create_collectible_parts") and b.create_collectible_parts:
		make_collectible = true
	
	var num_shapes = b.shape_owner_get_shape_count(0)
	var cur_shapes = []
	var new_shapes = []
	
	# get the shapes inside this body as an array of GLOBAL point sets
	for i in range(num_shapes):
		var shape = b.shape_owner_get_shape(0, i)
		var points = make_shape_global(b, shape)

		cur_shapes.append(points)
	
	# slice these shapes individually
	var half_slices_happened = false
	for shp in cur_shapes:
		var res = slice_shape(shp, p1, p2)
		new_shapes += res.bodies
		
		if res.result == "half":
			half_slices_happened = true

	if half_slices_happened:
		particles.general_feedback(b.global_position, "Almost!")
	
	# shape lists are the same? nothing happened, abort mission
	if cur_shapes.size() == new_shapes.size():
		print("Slicing didn't change anything")
		return []
	
	GlobalAudio.play_dynamic_sound(b, "slash")
	
	# determine which shapes belong together ("are in the same layer")
	var shape_layers = determine_shape_layers(new_shapes, p1, p2)
	
	create_visual_effects(b)
	
	# check if the shape needs to keep one part alive and/or die
	var attacker = null
	if attacking_throwable:
		attacker = attacking_throwable.modules.owner.get_owner()
	
	var params = { 
		'p1': p1,
		'p2': p2,
		'original_player_num': original_player_num,
		'object_died': false, 
		'is_keep_alive': false,
		'is_powerup': b.is_in_group("Powerups"),
		'is_player': b.is_in_group("Players"),
		'is_dumpling': b.is_in_group("Dumplings"),
		'attacking_throwable': attacking_throwable,
		'attacker': attacker 
	}

	check_keep_alive(b, shape_layers, params)
	handle_old_body_death(b, params)
	
	# create bodies for each set of points left over
	var new_bodies = []
	var new_body_params = { 
			'attacking_throwable': attacking_throwable,
			'player_num': original_player_num, 
			'is_powerup': params.is_powerup, 
			'is_dumpling': params.is_dumpling,
			'make_collectible': make_collectible,
			'color': original_color,
			'multi_color': use_multi_color
		}
		
	for key in shape_layers:
		var shp = shape_layers[key]

		if shape_manager.calculate_area(shp) < MIN_AREA_FOR_SHAPE: continue

		var body = create_body_from_shape_list(shp, new_body_params)
		new_bodies.append(body)
		
		shoot_body_away_from_line(p1, p2, body)
	
	return new_bodies

func create_visual_effects(b):
	if not b.is_in_group("KeepAlives"): return
	dramatic_slice.execute()

func check_keep_alive(b, shape_layers, params = {}):
	if not b.is_in_group("KeepAlives"): return
	
	params.is_keep_alive = true
	
	# Find the BIGGEST of them all
	# remove that shape from the list, change the current body to that shape
	var biggest_key = -1
	var biggest_area = -1
	
	for key in shape_layers:
		var shp = shape_layers[key]
		var area = shape_manager.calculate_area(shp)
		
		if area > biggest_area:
			biggest_area = area
			biggest_key = key
	
	# But if the biggest shape is still too small,
	# the player is officially dead
	var object_too_small = (biggest_area < PLAYER_MIN_AREA_FOR_SHAPE)
	
	if object_too_small and b.modules.status.can_die():
		params.object_died = true
		return
	
	var general_object_too_small = (biggest_area < PLAYER_MIN_AREA_GENERAL)
	var too_small = (params.is_player and general_object_too_small)
	if not too_small:
		var new_shape_for_this_body = shape_layers[biggest_key]
		shape_layers.erase(biggest_key)
		
		b.modules.shaper.destroy()
		b.modules.shaper.create_from_shape_list(new_shape_for_this_body)
		
		shoot_body_away_from_line(params.p1, params.p2, b)

	if params.is_player:
		b.modules.specialstatus.on_being_sliced(params.attacking_throwable)

func handle_old_body_death(b, params = {}):	
	if b.script and b.has_method("on_slice"):
		b.on_slice(params.attacking_throwable)
	
	if params.object_died:
		# if we died, the body keeps existing, just in a differnt form
		b.modules.status.die()
		return
	
	if params.is_keep_alive: return
	
	if params.is_powerup:
		b.reveal_powerup(params.attacker)
		return

	# destroy the old body completely; we'll create new ones
	# NOTE: this is actually the most common, basic way to deal with it
	# 		everything above are just exceptions
	if not b.modules.has('status'):
		b.queue_free()
		return
	
	b.modules.status.delete(params.attacking_throwable)

func shoot_body_away_from_line(p1, p2, body):
	var vec = (p2 - p1).normalized()
	
	var side_of_line = point_side_of_line(p1, p2, body.get_global_position())
	var shoot_vec
	if side_of_line < 0:
		shoot_vec = vec.rotated(-0.5*PI)
	else:
		shoot_vec = vec.rotated(0.5*PI)
	
	# randomize it a bit
	shoot_vec = shoot_vec.rotated((randf()-0.5)*0.1*PI)
	
	if body is RigidBody2D:
		body.plan_shoot_away(shoot_vec * SLICE_EXPLODE_FORCE)
	elif body is KinematicBody2D:
		body.modules.knockback.apply(shoot_vec * SLICE_EXPLODE_FORCE)

func point_side_of_line(p1, p2, point):
	return sign((p2.x - p1.x) * (point.y - p1.y) - (p2.y - p1.y)*(point.x - p1.x))

func determine_shape_layers(new_shapes, p1, p2):
	var saved_layers = []
	
	# initialize all to "no layer"
	for _i in range(new_shapes.size()):
		saved_layers.append(-1)
	
	# move through shapes left to right
	var cur_highest_layer = 0
	for i in range(new_shapes.size()):
		
		# not in a layer yet? create a new one, add us to it, and save the index
		# (the previous shapes never matched ours, so we can't be in the same layer)
		if saved_layers[i] == -1:
			saved_layers[i] = cur_highest_layer
			cur_highest_layer += 1
		
		# now check if we're adjacent to any other shapes
		var our_layer = saved_layers[i]
		for j in range(new_shapes.size()):
			if i == j: continue
			
			var their_layer = saved_layers[j]
			if their_layer == our_layer: continue
			
			if not is_adjacent(new_shapes[i], new_shapes[j], p1, p2): continue

			# they aren't in any group yet? put them in our group
			if their_layer == -1:
				saved_layers[j] = our_layer
				continue
			
			# they are part of an earlier group?
			# reduce us to that group and start checking again
			if their_layer < our_layer:
				saved_layers[i] = their_layer
				our_layer = their_layer
				j = -1 # start again from the front, because we need to take everyone else in our (previous) layer with us
	
	# now that each shape has a layer index,
	# simply build a dictionary from that
	var shape_layers = {}
	
	for i in range(new_shapes.size()):
		var shp = new_shapes[i]
		var layer = saved_layers[i]
		
		if not shape_layers.has(layer):
			shape_layers[layer] = []
		
		shape_layers[layer].append(shp)
	
	return shape_layers

# CRUCIAL NOTE:
# CollisionPolygon2D must be positioned at exactly 0
# Because we use the global transform of its PARENT, not the node itself, which means any offset is not taken into account and calculations are completely wrong
func slice_shape(shp, slice_start : Vector2, slice_end : Vector2) -> Dictionary:
	shp = shp + []

	var intersect_indices = []
	var intersect_points = []
	
	var shape1
	var shape2
	
	var succesful_slice : bool = false
	
	for i in range(shp.size()):
		var p1 : Vector2 = shp[i]
		var p2 : Vector2 = shp[(i+1) % int(shp.size())]
		
		var intersect_point = find_intersection_point(p1,p2,slice_start,slice_end)
		if not intersect_point: continue
		
		intersect_indices.append(i)
		intersect_points.append(intersect_point)
		
		if intersect_indices.size() >= 2:
			succesful_slice = true
			break
	
	var result = 'none'
	if intersect_indices.size() == 1:
		result = 'half'
	
	if not succesful_slice: 
		return { 'bodies': [shp], 'result': result }
	
	shape1 = shp.slice(0,intersect_indices[0])
	shape1.append(intersect_points[0])
	shape1.append(intersect_points[1])
	shape1 += shp.slice(intersect_indices[1]+1,shp.size()-1)
	
	shape2 = shp.slice(intersect_indices[0]+1, intersect_indices[1])
	shape2.push_front(intersect_points[0])
	shape2.append(intersect_points[1])
	
	return { 'bodies': [shape1, shape2], 'result': 'full' }

func create_body_from_shape_list(shapes : Array, params = {}) -> RigidBody2D:
	var body = player_part_scene.instance()
	
	# the average centroid of all centroids will be the center of the new body
	var avg_pos = Vector2.ZERO
	for shp in shapes:
		avg_pos += calculate_centroid(shp)
	
	avg_pos /= float(shapes.size())
	body.position = avg_pos
	
	map.ground.add_child(body)
	body.modules.shaper.create_from_shape_list(shapes)
	
	body.modules.status.set_player_num(params.player_num)
	body.modules.drawer.set_color(params.color)
	body.modules.drawer.set_multi_color(params.multi_color)
	
	if params.has('is_powerup') and params.is_powerup:
		body.modules.status.make_powerup_leftover()
	
	if params.has('is_dumpling') and params.is_dumpling:
		body.modules.status.make_dumpling_leftover()
	
	if params.player_num >= 0:
		body.add_to_group("PlayerParts")
	
	if params.has('make_collectible') and params.make_collectible:
		body.add_to_group("GhostParts")
	
	return body

###
#
# Helper functions
#
###

func make_shape_global(owner, shape : ConvexPolygonShape2D) -> Array:
	var trans = owner.get_global_transform()
	
	var points = Array(shape.points) + []
	for j in range(points.size()):
		points[j] = trans.xform(points[j])
	
	return points

func find_intersection_point(a1 : Vector2, a2 : Vector2, b1 : Vector2, b2 : Vector2):
	# 1) Rewrite vectors as "p + t r" and "q + u s" (0 <= t,u <= 1)
	var p = a1
	var r = (a2-a1)
	
	var q = b1
	var s = (b2-b1)
	
	# 2) Check if they are collinear OR parallel (non-intersecting)
	# (We can calculate intersection point, but for simplicity we just ignore both cases)
	var qminp = (q - p)
	var rxs = (r.cross(s))
	if rxs == 0:
		return null
	
	# 3) calculate "t" and "u" (supposing lines are endless and they will intersect)
	# (We already determined rxs to not be 0, so this will not fail)
	var t = qminp.cross(s) / rxs
	var u = qminp.cross(r) / rxs
	
	# NOTE: we add some leeway here to disallow extremely tiny shapes
	var epsilon = 0.0
	
	if (t >= epsilon and t <= 1.0-epsilon) and (u >= epsilon and u <= 1.0-epsilon):
		return p + t*r

func calculate_centroid(shp):
	var avg = Vector2.ZERO
	for point in shp:
		avg += point
	
	return avg / float(shp.size())

func is_adjacent(sh1, sh2, slice_start, slice_end):
	var epsilon : float = 0.05
	
	for p1 in sh1:
		
		var along_slicing_line = point_is_between(slice_start, slice_end, p1)
		if along_slicing_line: continue
		
		for p2 in sh2:
			along_slicing_line = point_is_between(slice_start, slice_end, p2)
			if along_slicing_line: continue
			
			if (p1-p2).length() > epsilon: continue

			return true

func point_is_between(a, b, c):
	# CRUCIAL NOTE! 
	#  => If you take this too SMALL, this will perform erratically, ruining the algorithm
	#  => If too big, it will obviously slice more than it should
	#  => However, seeing that the crossproduct uses non-normalized vectors, and distances can be huge, I think you're quite safe with epsilons > 0.1
	var epsilon = 0.1
	
	var crossproduct = (c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y)
	if abs(crossproduct) > epsilon: return false
	
	var dotproduct = (c.x - a.x) * (b.x - a.x) + (c.y - a.y)*(b.y - a.y)
	if dotproduct < 0: return false
	
	var squaredlengthba = (b - a).length_squared()
	if dotproduct > squaredlengthba:
		return false
	
	return true
