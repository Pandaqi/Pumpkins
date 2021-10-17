extends Node2D

onready var body = get_parent()

signal deflected()

func check_deflections(state, index):
	var body_calling_the_check = state.get_contact_collider_object(index)
	
	var res = Physics2DTestMotionResult.new()
	var result = body.test_motion(Vector2.ZERO, true, 0.00, res)
	
	if not result: return
	
	var obj = res.get_collider()
	if obj != body_calling_the_check: return
	if obj.is_in_group("Players"): return
	
	if body.last_velocity.length() <= 0.1: return

	# now MIRROR the velocity
	var vel = body.last_velocity
	var norm = res.get_collision_normal()

	var new_vel = -(2 * norm.dot(vel) * norm - vel)

	body.set_linear_velocity(new_vel)
	emit_signal("deflected")


#func check_deflection(state, index):
#	var obj = state.get_contact_collider_object(index)
#
#	if not obj.is_in_group("Deflectables"): return false
#
#	var vel = last_velocity
#	if vel.length() <= 0.1: return false
#
#	var norm = -state.get_contact_local_normal(index)
#
#	var new_vel = -(2 * norm.dot(vel) * norm - vel)
#	state.linear_velocity = new_vel
#
#	return true
