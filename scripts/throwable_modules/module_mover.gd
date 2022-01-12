extends Node2D

const LINEAR_DAMPING : float = 0.997
const WATER_DAMPING : float = 0.9935 # minute differences here can make a HUGE difference, as it's multiplied every frame
const MIN_SIGNIFICANT_VELOCITY : float = 90.0
const MIN_BOOMERANG_VELOCITY : float = 500.0
const GHOST_KNIFE_VELOCITY : float = 200.0

const HIGH_SPEED_THRESHOLD : float = 1000.0

const CURVE_SPEED : float = 0.016
const CURVE_DAMPING : float = 0.98

const BOOMERANG_PRECISION : float = 4.2 # higher is better
const GHOST_KNIFE_PRECISION : float = 5.0

onready var body = get_parent()
onready var sprite = get_node("../Sprite")
onready var players = get_node("/root/Main/Players")

var velocity : Vector2 = Vector2.ZERO
var curve_force : Vector3 = Vector3.ZERO # NOTE: fake 3D vector makes calculating forces easier for 2D
var constant_velocity : bool = false

var total_override_vec : Vector2
var total_override_influencers : int

var has_real_body : bool = false
var use_curve : bool = false
var boomerang_state : String = "flying"

onready var trail_particles = $TrailParticles

signal move_complete(dist)

func _ready():
	trail_particles.process_material = trail_particles.process_material.duplicate(true)

func set_body(val : bool):
	has_real_body = val

func get_velocity():
	return velocity

func rotate_velocity_to(target_vel, factor):
	if velocity.length() <= 0.03: return target_vel
	
	var vel_norm = velocity.normalized()
	var target_norm = target_vel.normalized()
	
	velocity = vel_norm.slerp(target_norm, factor) * velocity.length()

func set_velocity(vel):
	velocity = vel

func make_constant():
	constant_velocity = true

func at_high_speed():
	return velocity.length() >= HIGH_SPEED_THRESHOLD

func rotate_velocity(rot):
	velocity = velocity.rotated(rot)

func set_random_velocity():
	body.modules.status.is_stuck = false
	
	var rand_rot = 2*PI*randf()
	velocity = Vector2(cos(rand_rot), sin(rand_rot))*150

func add_to_override_vec(vec, _dt, size = GHOST_KNIFE_VELOCITY):
	total_override_vec += vec * size
	total_override_influencers += 1

func reset_override_vec():
	total_override_vec = Vector2.ZERO
	total_override_influencers = 0

func _physics_process(dt):
	if body.modules.status.being_held: return
	
	apply_curve(dt)
	apply_boomerang(dt)
	apply_ghost_knife(dt)
	move(dt)
	
	reset_override_vec()

func stop():
	velocity = Vector2.ZERO
	constant_velocity = false
	trail_particles.set_emitting(false)
	
	# TESTING IF THIS IS BETTER/MORE CONSISTENT => YES.
	body.modules.status.is_stuck = true

func came_to_standstill():
	stop()
	body.modules.owner.remove()

func overlapping_unreachable_location():
	var space_state = get_world_2d().direct_space_state
	
	var shp = CircleShape2D.new()
	shp.radius = body.modules.fakebody.knife_half_size
	
	var query_params = Physics2DShapeQueryParameters.new()
	query_params.set_shape(shp)
	query_params.transform.origin = body.global_position
	query_params.collision_layer = 64
	
	var result = space_state.intersect_shape(query_params)
	if not result: return false
	
	return true

func move(dt):
	if body.modules.status.is_stuck: return
	if body.modules.status.being_held: return
	
	var we_are_overridden = (total_override_vec.length() >= 0.03)
	if we_are_overridden:
		var avg = total_override_vec / float(total_override_influencers)
		velocity = avg
	
	if velocity.length() <= MIN_SIGNIFICANT_VELOCITY:
		if overlapping_unreachable_location(): 
			velocity = velocity.normalized() * (MIN_SIGNIFICANT_VELOCITY + 50.0)
		else:
			came_to_standstill()
			return
	
	trail_particles.set_emitting(true)
	trail_particles.process_material.direction = Vector3(velocity.x, velocity.y, 0)
	
	var old_pos = body.global_position
	if has_real_body:
		body.move_and_slide(velocity)
	else:
		body.set_position(body.get_position() + velocity * dt)
	
	body.set_rotation(velocity.angle())
	
	var damping = LINEAR_DAMPING
	if body.modules.status.in_water:
		damping = WATER_DAMPING
	
	var keep_pushing_through_non_solid = (body.modules.fakebody.nonsolids_hit.size() > 0)
	if not constant_velocity and not keep_pushing_through_non_solid:
		velocity *= damping
	
	var new_pos = body.global_position
	var distance_traveled = (new_pos - old_pos).length()
	emit_signal("move_complete", distance_traveled)

func apply_ghost_knife(dt):
	if not body.modules.status.type == "ghost_knife": return
	
	var speed = GHOST_KNIFE_VELOCITY
	var closest = players.get_closest_to(body.global_position)
	if not closest: return
	
	var cur_vec = velocity.normalized()
	if cur_vec.length() <= 0.03: cur_vec = Vector2.RIGHT
	
	var vec = (closest.global_position - body.global_position).normalized()

	var lerped_vec = cur_vec.slerp(vec, GHOST_KNIFE_PRECISION*dt)
	velocity = lerped_vec*speed

func apply_boomerang(dt):
	if not body.modules.status.type == "boomerang": return
	if body.modules.status.being_held: return
	
	sprite.rotate(10*PI*dt)
	if boomerang_state != "returning": return
	
	var cur_vel_norm = velocity.normalized()
	var target_vel_norm = body.modules.owner.get_vec_to().normalized()
	var cur_speed = velocity.length()
	if cur_speed < MIN_BOOMERANG_VELOCITY: cur_speed = MIN_BOOMERANG_VELOCITY
	
	velocity = cur_vel_norm.slerp(target_vel_norm, BOOMERANG_PRECISION*dt) * cur_speed

func apply_curve(_dt):
	if not body.modules.status.type == "curve": return
	if body.modules.status.being_held: return
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

func _on_Owner_owner_changed(num):
	var col = Color(1,1,1)
	if num >= 0:
		col = GlobalDict.player_colors[num]
	trail_particles.modulate = col

func make_curving(strength):
	var final_strength = strength*0.15
	var rand_dir = 1 if randf() <= 0.5 else -1
	curve_force = Vector3(0,0,final_strength)*rand_dir
