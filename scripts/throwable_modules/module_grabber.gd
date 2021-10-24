extends Node

onready var body = get_parent()
onready var timer = $Timer

var grabbing_by_owner_disabled : bool = false

func is_disabled_for_owner():
	return grabbing_by_owner_disabled

func disable():
	grabbing_by_owner_disabled = true
	timer.start()

func enable():
	grabbing_by_owner_disabled = false

func _on_Timer_timeout():
	enable()

func try_grabbing(other_body):
	if body.modules.status.being_held: return false
	if not other_body.is_in_group("Grabbers"): return false
	if grabbing_by_owner_disabled and body.modules.owner.is_body(other_body): return false
	return check_valid_grab(other_body)

func force_grab(other_body):
	complete_grab(other_body)

func check_valid_grab(other_body):
	if not other_body.modules.knives.is_mine(body): return false
	if other_body.modules.knives.at_max_capacity(): return false
	complete_grab(other_body)
	return true

func complete_grab(other_body):
	body.modules.mover.stop()
	body.modules.owner.set_owner(other_body)
	body.modules.status.reset_to_held_state()
	
	body.add_collision_exception_with(other_body)
	
	other_body.modules.knives.grab_knife(body)
	return true
