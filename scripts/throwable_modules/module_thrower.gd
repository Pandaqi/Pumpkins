extends Node2D

onready var body = get_parent()

func throw(thrower, vel):
	body.modules.status.reset_to_thrown_state()
	
	body.modules.owner.set_owner(thrower)
	body.modules.mover.set_velocity(vel)
	body.modules.grabber.disable()
	
	body.remove_collision_exception_with(thrower)
	
	var type = body.modules.status.type
	if type == "curve":
		body.modules.mover.make_curving(thrower.modules.slasher.get_curve_strength())
	
	elif type == "boomerang":
		body.modules.mover.boomerang_state = "flying"
	
