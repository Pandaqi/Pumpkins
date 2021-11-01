extends Node

const GRAB_DISABLE_DURATION : float = 0.08

onready var body = get_parent()
onready var timer = $Timer

var grabbing_by_owner_disabled : bool = false
var forbidden_node = null

func is_disabled_for_owner():
	return grabbing_by_owner_disabled

func disable(node):
	forbidden_node = node
	grabbing_by_owner_disabled = true
	timer.wait_time = GRAB_DISABLE_DURATION
	timer.start()

func enable():
	grabbing_by_owner_disabled = false
	forbidden_node = null
	
func _on_Timer_timeout():
	enable()

func try_grabbing(other_body):
	if body.modules.status.being_held and body.modules.owner.is_a_player(): return false
	if body.modules.status.is_forbidden: return false
	
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
	body.modules.knockback.remove()
	
	body.add_collision_exception_with(other_body)
	
#	if body.modules.fakebody.has_real_body:
#		body.modules.fakebody.disable_real_collisions()
	
	other_body.modules.knives.grab_knife(body)
	return true
