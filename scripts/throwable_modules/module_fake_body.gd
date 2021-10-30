extends Node2D

onready var body = get_parent()

var has_real_body : bool = false

var knife_half_size = 0.5 * (0.25*256)
var back_raycast = null
var front_raycast = null
var side_raycasts = null
var nonsolids_hit = []
var space_state = null

var collision_exceptions = []

func set_body(val : bool):
	has_real_body = val
	
	if not has_real_body: disable_real_collisions()

func disable_real_collisions():
	body.collision_layer = 32 # 2^5 => 6th layer
	body.collision_mask = 32

func enable_real_collisions():
	body.collision_layer = 1 + 32
	body.collision_mask = 1 + 32

func _physics_process(dt):
	reset_all()
	
	if body.modules.status.being_held and body.modules.owner.is_a_player(): return
	space_state = get_world_2d().direct_space_state 
	
	shoot_raycast(dt)
	shoot_back_raycast()
	shoot_side_raycast()

func reset_all():
	nonsolids_hit = []
	back_raycast = null
	front_raycast = null
	side_raycasts = null

func waiting_for_pickup():
	if body.modules.status.is_stuck: return true
	if body.modules.owner.has_none(): return true
	if body.modules.owner.is_friendly(): return true
	return false

func shoot_pickup_raycast(start, end):
	return space_state.intersect_ray(start, end, build_exclude_array(), 2)

func shoot_side_raycast():
	if not waiting_for_pickup(): return
	
	var normal = Vector2(cos(body.rotation), sin(body.rotation))
	var ortho_normal = normal.rotated(0.5*PI)

	var start = body.global_position
	var end = body.global_position + ortho_normal * knife_half_size * 1.5
	
	var result = shoot_pickup_raycast(start, end)
	side_raycasts = result
	if result: return
	
	end = body.global_position - ortho_normal * knife_half_size * 1.5
	result = shoot_pickup_raycast(start, end)
	side_raycasts = result

func shoot_back_raycast():
	if not waiting_for_pickup(): return

	# This one extends considerably, so that bots (or weirder shapes) can also pick it up
	var normal = Vector2(cos(body.rotation), sin(body.rotation))
	var start = body.global_position + normal * knife_half_size
	var end = body.global_position - normal * knife_half_size * 1.5
	
	var result = shoot_pickup_raycast(start, end)
	back_raycast = result

func build_exclude_array():
	var exclude = []
	
	if has_real_body:
		exclude.append(body)
	
	if body.modules.owner.has_none(): return exclude
	if not body.modules.grabber.is_disabled_for_owner(): return exclude
	
	exclude.append(body.modules.owner.get_owner())
	return exclude

func shoot_raycast(dt):
	if body.modules.status.is_stuck: return

	var margin = 6
	var vel = body.modules.mover.velocity
	var rot = body.rotation
	var raycast_length = 2*knife_half_size + vel.length() * dt + margin

	var normal = vel.normalized()
	if vel.length() <= 0.1: normal = Vector2(cos(rot), sin(rot))
	
	var start = body.global_position - normal*knife_half_size
	var end = start + normal * raycast_length
	
	clean_up_collision_exceptions()
	
	var exclude = build_exclude_array() + collision_exceptions
	var collision_layer = 1 + 4 + 8 + 16 # layer 1 (all; 2^0), 3 (loose parts; 2^2) and 4 (powerups; 2^3) and 5 (ghosts; 2^4)
	
	var result = null
	var hit_a_nonsolid : bool = true
	
	nonsolids_hit = []
	while hit_a_nonsolid:
		hit_a_nonsolid = false
		
		result = space_state.intersect_ray(start, end, exclude, collision_layer)
		
		if not result: break
		
		var hit_body = result.collider
		if not hit_body.is_in_group("NonSolids"): break
		
		hit_a_nonsolid = true
		exclude += [hit_body]
		nonsolids_hit.append(hit_body)
	
	front_raycast = result

func add_collision_exception(other_body):
	collision_exceptions.append(other_body)

func reset_collision_exceptions():
	collision_exceptions = []

func clean_up_collision_exceptions():
	for i in range(collision_exceptions.size()-1,-1,-1):
		var obj = collision_exceptions[i]
		if not obj or not is_instance_valid(obj):
			collision_exceptions.remove(i)

func get_top_pos():
	var rot = body.rotation
	var offset_vec = Vector2(cos(rot), sin(rot))
	return body.global_position + offset_vec*knife_half_size

func get_bottom_pos():
	var rot = body.rotation
	var offset_vec = Vector2(cos(rot), sin(rot))
	return body.global_position - offset_vec*knife_half_size
