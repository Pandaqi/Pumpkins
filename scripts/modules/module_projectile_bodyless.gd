extends Node2D

const LINEAR_DAMPING : float = 0.995

const MIN_SIGNIFICANT_VELOCITY : float = 20.0

const GHOST_RAND_ROTATION : float = 0.05
const GHOST_SLOWDOWN : float = 0.995

const CURVE_SPEED : float = 0.016
const CURVE_DAMPING : float = 0.98

const VELOCITY_LEFT_AFTER_DEFLECTION : float = 0.9
const MIN_TIME_BETWEEN_DEFLECTIONS : float = 50.0 # milliseconds

const BOOMERANG_PRECISION : float = 3.0 # higher is better

onready var body = get_parent()
onready var timer = $Timer
onready var sprite = get_node("../Sprite")
onready var anim_player = get_node("../AnimationPlayer")

onready var particles = get_node("/root/Main/Particles")
onready var slicer = get_node("/root/Main/Slicer")
onready var mode = get_node("/root/Main/ModeManager")

var knife_half_size = 0.5 * (0.25*256)

var ignore_deflections : bool = false
var last_deflection_time : float
var collision_exceptions = []

var num_succesful_actions : int = 0

var being_held : bool = false
var my_owner = null # NOTE "owner" is a registered word with Godot, so use something else
var is_stuck : bool = false

var velocity : Vector2 = Vector2.ZERO
var curve_force : Vector3 = Vector3.ZERO # NOTE: fake 3D vector makes calculating forces easier for 2D
var grabbing_disabled : bool = false

var use_curve : bool = false
var is_boomerang : bool = false
var boomerang_state : String = "flying"

func set_owner(o):
	my_owner = o
	sprite.set_frame(my_owner.modules.status.player_num)
	anim_player.stop()

func get_owner():
	return my_owner

func has_no_owner():
	return (my_owner == null)

func remove_owner():
	my_owner = null
	sprite.set_frame(8)
	anim_player.play("Highlight")

func get_owner_rotation():
	if has_no_owner(): return 0
	return my_owner.rotation

func set_velocity(vel):
	velocity = vel

func set_random_velocity():
	is_stuck = false
	
	var rand_rot = 2*PI*randf()
	velocity = Vector2(cos(rand_rot), sin(rand_rot))*150

func make_boomerang():
	is_boomerang = true
	boomerang_state = "flying"

func make_curving(strength):
	use_curve = true
	
	var final_strength = strength*0.4
	var rand_dir = 1 if randf() <= 0.5 else -1
	curve_force = Vector3(0,0,final_strength)*rand_dir

func reset():
	is_boomerang = false
	is_stuck = false
	use_curve = false
	boomerang_state = "flying"
	sprite.set_rotation(0.5*PI)

func throw(vel):
	num_succesful_actions = 0
	velocity = vel
	disable_grabbing()

func _physics_process(dt):
	if being_held: return
	
	apply_boomerang(dt)
	move(dt)
	shoot_raycast()
	shoot_back_raycast()

func apply_boomerang(dt):
	if not is_boomerang: return
	
	sprite.rotate(10*PI*dt)
	if boomerang_state != "returning": return
	
	var vec_to_owner = my_owner.get_global_position() - body.get_position()
	var cur_vel_norm = velocity.normalized()
	var target_vel_norm = vec_to_owner.normalized()
	velocity = cur_vel_norm.slerp(target_vel_norm, BOOMERANG_PRECISION*dt) * velocity.length()

func move(dt):
	if is_stuck: return
	if velocity.length() <= MIN_SIGNIFICANT_VELOCITY:
		stop()
		return
	
	apply_curve()
	
	body.set_position(body.get_position() + velocity * dt)
	body.set_rotation(velocity.angle())
	
	velocity *= LINEAR_DAMPING

func apply_curve():
	if not use_curve: return
	if curve_force.length() <= 0.05: return
	
	var res = calculate_next_curve_step(velocity, curve_force)
	velocity = res.velocity
	curve_force = res.curve

func calculate_next_curve_step(vel : Vector2, curve : Vector3):
	# ( = Magnus force; F = k(omega x velocity))
	var vel_with_z_plane = Vector3(vel.x, vel.y, 0)
	var magnus_vec = vel_with_z_plane.cross(curve)
	
	var converted_curve_speed = CURVE_SPEED
	
	var val = converted_curve_speed * magnus_vec
	var val_without_z_plane = Vector2(val.x, val.y)
	
	# don't forget to damp the curve force!
	curve *= CURVE_DAMPING
	if curve.length() <= 0.01: curve = Vector3.ZERO
	
	return {
		"velocity": vel + val_without_z_plane,
		"curve": curve
	}

func shoot_back_raycast():
	if not (is_stuck or has_no_owner()): return

	var space_state = get_world_2d().direct_space_state 

	# This one extends considerably, so that bots (or weirder shapes) can also pick it up
	var normal = Vector2(cos(body.rotation), sin(body.rotation))
	var start = body.get_global_position() + normal*knife_half_size
	var end = body.get_global_position() - normal * knife_half_size * 4
	
	var exclude = []
	if grabbing_disabled and not has_no_owner():
		exclude += [my_owner]
	var collision_layer = 2
	
	var result = space_state.intersect_ray(start, end, exclude, collision_layer)
	if not result: return
	
	var hit_body = result.collider
	if hit_body.is_in_group("Grabbers"):
		check_knife_grab(hit_body)

func shoot_raycast():
	if is_stuck: return
	
	var space_state = get_world_2d().direct_space_state
	
	var margin = 6
	var raycast_length = 2*knife_half_size + velocity.length() * 0.016 + margin

	var normal = velocity.normalized()
	if velocity.length() <= 0.1:
		var rot = body.rotation
		normal = Vector2(cos(rot), sin(rot))
	
	var start = body.get_global_position() - normal*knife_half_size
	var end = start + normal * raycast_length
	
	clean_up_collision_exceptions()
	
	var exclude = collision_exceptions
	if grabbing_disabled and not has_no_owner():
		exclude += [my_owner]
	
	var collision_layer = 1 + 4 + 8 + 16 # layer 1 (all; 2^0), 3 (loose parts; 2^2) and 4 (powerups; 2^3) and 5 (ghosts; 2^4)
	
	var result 
	var hit_a_ghost = true
	while hit_a_ghost:
		hit_a_ghost = false
		
		result = space_state.intersect_ray(start, end, exclude, collision_layer)
		
		if not result: break
		if not result.collider.is_in_group("Players"): break
		if not result.collider.modules.status.is_ghost: break
		
		hit_a_ghost = true
		exclude += [result.collider]
		
		apply_ghost_effect()
	
	if not result: return

	var hit_body = result.collider
	var succesful_grab = false
	if hit_body.is_in_group("Grabbers"):
		succesful_grab = check_knife_grab(hit_body)
	
	if succesful_grab: return
	
	if hit_body.is_in_group("Sliceables"):
		slice_through_body(result.collider)
		num_succesful_actions += 1
	elif hit_body.is_in_group("Stuckables"):
		get_stuck(result)
		
		var custom_behavior = (hit_body.script and hit_body.has_method("on_knife_entered"))
		if custom_behavior:
			hit_body.on_knife_entered(body)
		else:
			if GlobalDict.cfg.stuck_reset:
				remove_owner()
	else:
		deflect(result)
	
	if is_boomerang:
		boomerang_state = "returning"

func stop():
	record_succesful_actions()
	
	velocity = Vector2.ZERO
	remove_owner()

func record_succesful_actions():
	if num_succesful_actions <= 0: return
	if has_no_owner(): return
	my_owner.modules.statistics.record("knives_succesful", 1)

func get_stuck(result):
	velocity = Vector2.ZERO
	body.set_position(result.position)
	
	var wanted_normal = -result.normal
	body.set_rotation(wanted_normal.angle())
	is_stuck = true
	
	record_succesful_actions()

func get_knife_top_pos():
	var rot = body.rotation
	var offset_vec = Vector2(cos(rot), sin(rot))
	return body.get_global_position() + offset_vec*knife_half_size

func get_knife_bottom_pos():
	var rot = body.rotation
	var offset_vec = Vector2(cos(rot), sin(rot))
	return body.get_global_position() - offset_vec*knife_half_size

func slice_through_body(obj):
	if obj.is_in_group("Players"):
		if obj.modules.powerups.repel_knives:
			var normal = (obj.get_global_position() - body.get_global_position()).normalized()
			var rand_normal = normal.rotated((randf() - 0.5)*0.25*PI)
			deflect({ 'normal': rand_normal })
			return
	
	var normal = velocity.normalized()
	var center = body.get_global_position()
	var start = center - normal * 500
	var end = center + normal * 500
	
	particles.create_slash(get_knife_bottom_pos(), normal)

	var result = slicer.slice_bodies_hitting_line(start, end, [], [obj], my_owner)
	if result.size() <= 0: return false

	collision_exceptions.append(obj)
	
	for sliced_body in result:
		collision_exceptions.append(sliced_body)
	
	var penalty = mode.get_player_slicing_penalty()
	my_owner.modules.collector.collect(penalty)
	
	my_owner.modules.statistics.record("players_sliced", 1)

	return true

func deflect(res):
	var going_too_slow = (velocity.length() <= 0.1)
	if going_too_slow: return
	
	var too_soon = (OS.get_ticks_msec() - last_deflection_time) < MIN_TIME_BETWEEN_DEFLECTIONS
	if too_soon: return

	# now MIRROR the velocity
	var norm = res.normal
	var new_vel = -(2 * norm.dot(velocity) * norm - velocity)

	velocity = VELOCITY_LEFT_AFTER_DEFLECTION*new_vel
	last_deflection_time = OS.get_ticks_msec()
	reset_collision_exceptions()

# Ghosts slow down moving knifes
func apply_ghost_effect():
	velocity *= GHOST_SLOWDOWN
	velocity = velocity.rotated((randf()-0.5)*GHOST_RAND_ROTATION)

func reset_collision_exceptions():
	collision_exceptions = []

func clean_up_collision_exceptions():
	for i in range(collision_exceptions.size()-1,-1,-1):
		var obj = collision_exceptions[i]
		if not obj or not is_instance_valid(obj):
			collision_exceptions.remove(i)

func disable_grabbing():
	grabbing_disabled = true
	timer.start()

func enable_grabbing():
	grabbing_disabled = false

func _on_Timer_timeout():
	enable_grabbing()

func check_knife_grab(other_body):
	if not other_body.modules.knives.is_mine(body): return false

	other_body.modules.knives.grab_knife(body)
	return true
