extends Node2D

onready var body = get_parent()

var has_real_body : bool = false

var knife_half_size = 0.5 * (0.25*256)
var back_raycast = null
var front_raycast = null
var ghosts_hit = []

var collision_exceptions = []

func set_body(val : bool):
	has_real_body = val
	
	if not has_real_body: disable_real_collisions()

func disable_real_collisions():
	body.collision_layer = 0 
	body.collision_mask = 0

func _physics_process(_dt):
	reset_all()
	
	if body.modules.status.being_held: return
	
	shoot_raycast()
	shoot_back_raycast()

func reset_all():
	ghosts_hit = []
	back_raycast = null
	front_raycast = null

func shoot_back_raycast():
	if not (body.modules.status.is_stuck or body.modules.owner.has_none()): return

	var space_state = get_world_2d().direct_space_state 

	# This one extends considerably, so that bots (or weirder shapes) can also pick it up
	var normal = Vector2(cos(body.rotation), sin(body.rotation))
	var start = body.global_position + normal*knife_half_size
	var end = body.global_position - normal * knife_half_size * 4
	
	var exclude = build_exclude_array()
	var collision_layer = 2
	
	var result = space_state.intersect_ray(start, end, exclude, collision_layer)
	back_raycast = result

func build_exclude_array():
	var exclude = []
	
	if has_real_body:
		exclude.append(body)
	
	if body.modules.owner.has_none(): return exclude
	if not body.modules.grabber.grabbing_disabled: return exclude
	exclude.append(body.modules.owner.get_owner())
	
	return exclude

func shoot_raycast():
	if body.modules.status.is_stuck: return
	
	var space_state = get_world_2d().direct_space_state
	
	var margin = 6
	var vel = body.modules.mover.velocity
	var rot = body.rotation
	var raycast_length = 2*knife_half_size + vel.length() * 0.016 + margin

	var normal = vel.normalized()
	if vel.length() <= 0.1: normal = Vector2(cos(rot), sin(rot))
	
	var start = body.global_position - normal*knife_half_size
	var end = start + normal * raycast_length
	
	clean_up_collision_exceptions()
	
	var exclude = build_exclude_array() + collision_exceptions
	var collision_layer = 1 + 4 + 8 + 16 # layer 1 (all; 2^0), 3 (loose parts; 2^2) and 4 (powerups; 2^3) and 5 (ghosts; 2^4)
	
	var result = null
	var hit_a_ghost : bool = true
	
	ghosts_hit = []
	while hit_a_ghost:
		hit_a_ghost = false
		
		result = space_state.intersect_ray(start, end, exclude, collision_layer)
		
		if not result: break
		if not result.collider.is_in_group("Players"): break
		if not result.collider.modules.status.is_ghost: break
		
		hit_a_ghost = true
		exclude += [result.collider]
		ghosts_hit.append(result.collider)
	
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
