extends Node2D

const LINEAR_DAMPING : float = 0.995
const MIN_SIGNIFICANT_VELOCITY : float = 20.0

const CURVE_SPEED : float = 0.016
const CURVE_DAMPING : float = 0.98

const BOOMERANG_PRECISION : float = 3.0 # higher is better

onready var body = get_parent()
onready var sprite = get_node("../Sprite")

var velocity : Vector2 = Vector2.ZERO
var curve_force : Vector3 = Vector3.ZERO # NOTE: fake 3D vector makes calculating forces easier for 2D

var use_curve : bool = false
var boomerang_state : String = "flying"

onready var trail_particles = $TrailParticles

func _ready():
	trail_particles.process_material = trail_particles.process_material.duplicate(true)

func set_velocity(vel):
	velocity = vel

func set_random_velocity():
	body.modules.status.is_stuck = false
	
	var rand_rot = 2*PI*randf()
	velocity = Vector2(cos(rand_rot), sin(rand_rot))*150

func _physics_process(dt):
	if body.modules.status.being_held: return
	
	apply_curve(dt)
	apply_boomerang(dt)
	move(dt)

func stop():
	velocity = Vector2.ZERO
	trail_particles.set_emitting(false)

func came_to_standstill():
	stop()
	body.modules.owner.remove()

func move(dt):
	if body.modules.status.is_stuck: return
	if body.modules.status.being_held: return
	if velocity.length() <= MIN_SIGNIFICANT_VELOCITY:
		came_to_standstill()
		return
	
	trail_particles.set_emitting(true)
	trail_particles.process_material.direction = Vector3(velocity.x, velocity.y, 0)
	
	body.set_position(body.get_position() + velocity * dt)
	body.set_rotation(velocity.angle())
	
	velocity *= LINEAR_DAMPING

func apply_boomerang(dt):
	if not body.modules.status.type == "boomerang": return
	
	sprite.rotate(10*PI*dt)
	if boomerang_state != "returning": return
	
	var cur_vel_norm = velocity.normalized()
	var target_vel_norm = body.modules.owner.get_vec_to().normalized()
	velocity = cur_vel_norm.slerp(target_vel_norm, BOOMERANG_PRECISION*dt) * velocity.length()

func apply_curve(dt):
	if not body.modules.status.type == "curve": return
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
	var final_strength = strength*0.4
	var rand_dir = 1 if randf() <= 0.5 else -1
	curve_force = Vector3(0,0,final_strength)*rand_dir
