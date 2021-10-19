extends Node2D

const SLICE_EXPLODE_FORCE : float = 1000.0
const MIN_AREA_FOR_SHAPE : float = 350.0

# NOTE: if player falls below this size, they die
const PLAYER_MIN_AREA_FOR_SHAPE : float = 600.0

var player_part_scene = preload("res://scenes/player_part.tscn")

onready var main_node = get_parent()
onready var dramatic_slice = get_node("/root/Main/DramaticSlice")
onready var map = get_node("/root/Main/Map")
onready var shape_manager = get_node("/root/Main/ShapeManager")

var start_point
var end_point

# Debug drawing
func _input(ev):
	if ev is InputEventMouseMotion:
		update()
	
	if (ev is InputEventMouseButton):
		if ev.pressed:
			start_point = get_global_mouse_position()
			end_point = null
		else:
			end_point = get_global_mouse_position()
			slice_bodies_hitting_line(start_point, end_point)

func _draw():
	if not start_point: return
	
	var a = start_point
	var b = get_global_mouse_position()
	if end_point: b = end_point
	
	draw_line(a, b, Color(0,0,0), 2)

# Actual slicing functionality
func slice_bodies_hitting_line(p1 : Vector2, p2 : Vector2, exclude = [], include = []):
	# debug draw (for me)
	start_point = p1
	end_point = p2
	update()
	
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
		final_bodies += slice_body(b, p1, p2)
	
	return final_bodies

func slice_body(b, p1, p2):
	var original_player_num = -1
	if b.modules.has("status"):
		original_player_num = b.modules.status.player_num
	
	var num_shapes = b.shape_owner_get_shape_count(0)
	var cur_shapes = []
	var new_shapes = []
	
	# get the shapes inside this body as an array of GLOBAL point sets
	for i in range(num_shapes):
		var shape = b.shape_owner_get_shape(0, i)
		var points = make_shape_global(b, shape)

		cur_shapes.append(points)
	
	# slice these shapes individually
	for shp in cur_shapes:
		var res = slice_shape(shp, p1, p2)
		new_shapes += res
	
	# shape lists are the same? nothing happened, abort mission
	if cur_shapes.size() == new_shapes.size():
		print("Slicing didn't change anything")
		return []
	
	# determine which shapes belong together ("are in the same layer")
	var shape_layers = determine_shape_layers(new_shapes, p1, p2)
	
	var is_player_body = b.is_in_group("Players")
	var is_powerup = b.is_in_group("Powerups")
	var player_died = false
	
	if is_player_body:
		
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
		print(biggest_area)
		if biggest_area < PLAYER_MIN_AREA_FOR_SHAPE:
			player_died = true
		
		else:
			var new_shape_for_this_body = shape_layers[biggest_key]
			shape_layers.erase(biggest_key)
			
			b.modules.shaper.destroy()
			b.modules.shaper.create_from_shape_list(new_shape_for_this_body)

	if player_died:
		# if we died, the body keeps existing, just in a differnt form
		b.modules.status.die()
		
		# NOW ask the main node to check game over, because the "dying" has finished
		main_node.player_died(original_player_num)
	
	elif (not is_player_body):
		if is_powerup:
			b.reveal_powerup()
		
		else:
			# destroy the old body completely; we'll create new ones
			b.modules.status.delete()
	
	# create bodies for each set of points left over
	var vec = (p2 - p1).normalized()

	var new_bodies = []
	for key in shape_layers:
		var shp = shape_layers[key]

		if shape_manager.calculate_area(shp) < MIN_AREA_FOR_SHAPE: continue
		
		var body = create_body_from_shape_list(shp, { 'player_num': original_player_num, 'is_powerup': is_powerup })
		new_bodies.append(body)
		
		var side_of_line = point_side_of_line(p1, p2, body.get_global_position())
		var shoot_vec
		if side_of_line < 0:
			shoot_vec = vec.rotated(-0.5*PI)
		else:
			shoot_vec = vec.rotated(0.5*PI)
		
		# randomize it a bit
		shoot_vec = shoot_vec.rotated((randf()-0.5)*0.1*PI)
		
		body.plan_shoot_away(shoot_vec * SLICE_EXPLODE_FORCE)
	
	if is_player_body:
		dramatic_slice.execute()
	
	return new_bodies

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

func slice_shape(shp, slice_start : Vector2, slice_end : Vector2) -> Array:
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
	
	if not succesful_slice: return [shp]
	
	shape1 = shp.slice(0,intersect_indices[0])
	shape1.append(intersect_points[0])
	shape1.append(intersect_points[1])
	shape1 += shp.slice(intersect_indices[1]+1,shp.size()-1)
	
	shape2 = shp.slice(intersect_indices[0]+1, intersect_indices[1])
	shape2.push_front(intersect_points[0])
	shape2.append(intersect_points[1])
	
	return [shape1, shape2]

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
	if params.has('is_powerup') and params.is_powerup:
		body.modules.status.make_powerup_leftover()
	
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
