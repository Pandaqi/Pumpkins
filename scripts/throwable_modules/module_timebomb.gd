extends Node2D

const TIMEBOMB_DURATION : float = 20.0
onready var timer = $Timer
onready var body = get_parent()

func activate():
	timer.wait_time = TIMEBOMB_DURATION
	timer.start()

func deactivate():
	timer.stop()

func _on_Timer_timeout():
	var my_owner = body.modules.owner.get_owner()
	if not my_owner: return
	
	my_owner.modules.knives.throw_knife(body)
