extends Node2D

const DURATION = { 'min': 0.5, 'max': 4.5 }
const DIST_FOR_MIN_INVINCIBILITY : float = 1400.0

var is_invincible : bool = false

onready var timer = $Timer
onready var body = get_parent().get_parent()

func start(throwable):
	var dist = throwable.modules.distancetracker.last_throw_dist
	var ratio = (1.0 - min(dist / DIST_FOR_MIN_INVINCIBILITY, 1.0))
	var raw_duration = ratio * DURATION.max
	var duration = max(raw_duration, DURATION.min)
	
	if not GlobalDict.cfg.invincibility_depends_on_distance:
		duration = DURATION.max
	
	timer.wait_time = duration
	timer.start()
	
	is_invincible = true

	# TO DO: get our own flicker animation to prevent this spaghetti code?
	body.modules.respawner.anim_player.play("RespawnFlicker")

func stop():
	is_invincible = false
	body.modules.respawner.anim_player.stop()
	body.modulate.a = 1.0

func _on_Timer_timeout():
	stop()
