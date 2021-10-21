extends PhysicsBody2D

# 0->1, 0 means we NEVER reach our new rotation, 1 means we INSTANTLY reach our new rotation
const AGILITY : float = 0.6
const MAX_ANGULAR_VEL_ON_IMPACT : float = 50.0

var modules = {}
var shoot_away : Vector2 = Vector2.ZERO
var teleport_pos : Vector2 = Vector2.ZERO

var last_velocity : Vector2 = Vector2.ZERO
var last_rotation : float = 0.0

func _ready():
	register_modules()

func register_modules():
	for child in get_children():
		if not is_instance_valid(child): continue
		var key = child.name.to_lower()
		modules[key] = child

func slowly_orient_towards_vec(vec, factor : float = 1.0):
	var cur_vec = get_forward_vec()
	var lerp_vec = cur_vec.slerp(vec, AGILITY*factor)
	set_rotation(lerp_vec.angle())

func get_forward_vec():
	var rot = get_rotation()
	return Vector2(cos(rot), sin(rot))

func plan_shoot_away(vec):
	shoot_away = vec

func plan_teleport(pos):
	teleport_pos = pos

func _integrate_forces(state):
	#state.angular_velocity = 0.0
	
	if teleport_pos.length() > 0.5:
		state.transform.origin = teleport_pos
		teleport_pos = Vector2.ZERO

	if shoot_away.length() > 0.5:
		state.linear_velocity = shoot_away
		state.angular_velocity = (randf()-0.5)*MAX_ANGULAR_VEL_ON_IMPACT
		shoot_away = Vector2.ZERO
	
	if modules.has('projectile'):
		modules.projectile._integrate_forces(state)
	
	last_velocity = state.linear_velocity
	last_rotation = get_rotation()

func reset_velocity_to_last_point(state):
	state.linear_velocity = last_velocity
	set_rotation(last_rotation)
