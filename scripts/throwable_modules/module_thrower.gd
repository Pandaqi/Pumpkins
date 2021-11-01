extends Node2D

onready var body = get_parent()
onready var map = get_node("/root/Main/Map")

func throw_from_object(obj, force):
	var old_pos = body.global_position
	var old_rot = body.global_rotation
	var vec = (old_pos - obj.global_position).normalized() * force
	
	body.get_parent().remove_child(body)
	map.knives.add_child(body)
	
	body.set_position(old_pos)
	body.set_rotation(old_rot)

	throw(obj, vec)

func throw(thrower, vel):
	body.modules.status.reset_to_thrown_state()
	
	if thrower and thrower.is_in_group("Players"): 
		body.modules.owner.set_owner(thrower)
		body.remove_collision_exception_with(thrower)
	
	body.modules.mover.set_velocity(vel)
	body.modules.grabber.disable(thrower)
	
#	if body.modules.fakebody.has_real_body:
#		body.modules.fakebody.enable_real_collisions()
	
	var type = body.modules.status.type
	if type == "curve":
		body.modules.mover.make_curving(thrower.modules.slasher.get_curve_strength())
	
	elif type == "boomerang":
		body.modules.mover.boomerang_state = "flying"
	
	body.modules.distancetracker.reset()
