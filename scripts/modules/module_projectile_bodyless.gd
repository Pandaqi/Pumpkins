extends Node2D

const LINEAR_DAMPING : float = 0.999

const CURVE_SPEED : float = 0.016
const CURVE_DAMPING : float = 0.98

const BOOMERANG_PRECISION : float = 3.0 # higher is better

onready var body = get_parent()
onready var timer = $Timer
onready var sprite = get_node("../Sprite")

onready var slicer = get_node("/root/Main/Slicer")

var ignore_deflections : bool = false
var collision_exceptions = []

var being_held : bool = false
var my_owner = null # NOTE "owner" is a registered word with Godot, so use something else

var velocity : Vector2 = Vector2.ZERO
var curve_force : Vector3 = Vector3.ZERO # NOTE: fake 3D vector makes calculating forces easier for 2D
var grabbing_disabled : bool = false

var use_curve : bool = false
var is_boomerang : bool = false
var boomerang_state : String = "flying"

func set_owner(o):
	my_owner = o

func has_no_owner():
	return (my_owner == null)

func get_owner_rotation():
	if has_no_owner(): return 0
	return my_owner.rotation

func set_velocity(vel):
	velocity = vel

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
	boomerang_state = "flying"
	sprite.set_rotation(0.5*PI)

func throw(vel):
	velocity = vel
	disable_grabbing()

func _physics_process(dt):
	if being_held: return
	
	apply_boomerang(dt)
	move(dt)
	shoot_raycast()

func apply_boomerang(dt):
	if not is_boomerang: return
	
	sprite.rotate(10*PI*dt)
	if boomerang_state != "returning": return
	
	var vec_to_owner = my_owner.get_global_position() - body.get_position()
	var cur_vel_norm = velocity.normalized()
	var target_vel_norm = vec_to_owner.normalized()
	velocity = cur_vel_norm.slerp(target_vel_norm, BOOMERANG_PRECISION*dt) * velocity.length()

func move(dt):
	if velocity.length() <= 0.05:
		velocity = Vector2.ZERO
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

func shoot_raycast():
	var space_state = get_world_2d().direct_space_state
	
	var raycast_length = 50 * (velocity.length() / 1000.0)
	
	var normal = velocity.normalized()
	var start = body.get_global_position()
	var end = start + normal * raycast_length
	
	clean_up_collision_exceptions()
	
	var exclude = collision_exceptions
	if grabbing_disabled:
		exclude += [my_owner]
	
	var collision_layer = 1 + 4 + 8 # layer 1 (all; 2^0), 3 (loose parts; 2^2) and 4 (powerups; 2^3)
	
	var result = space_state.intersect_ray(start, end, exclude, collision_layer)
	if not result: return

	var hit_body = result.collider
	var succesful_grab = false
	if hit_body.is_in_group("Grabbers"):
		succesful_grab = check_knife_grab(hit_body)
	
	if succesful_grab: return
	
	if hit_body.is_in_group("Sliceables"):
		slice_through_body(result.collider)
	elif hit_body.is_in_group("Stuckables"):
		get_stuck(result)
	else:
		deflect(result)
	
	if is_boomerang:
		boomerang_state = "returning"

func get_stuck(result):
	var dist_to_hit = (result.position - self.get_global_position()).length()
	if dist_to_hit > 10: return
	if is_boomerang: return # boomerangs never get stuck; they just return
	
	my_owner = null
	velocity = Vector2.ZERO

func slice_through_body(obj):
	var normal = velocity.normalized()
	var center = body.get_global_position()
	var start = center - normal * 500
	var end = center + normal * 500

	var result = slicer.slice_bodies_hitting_line(start, end, [], [obj])
	if result.size() <= 0: return false

	collision_exceptions.append(obj)
	
	for sliced_body in result:
		collision_exceptions.append(sliced_body)

	return true

func deflect(res):
	if velocity.length() <= 0.1: return

	# now MIRROR the velocity
	var norm = res.normal
	var new_vel = -(2 * norm.dot(velocity) * norm - velocity)

	velocity = new_vel
	reset_collision_exceptions()

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
