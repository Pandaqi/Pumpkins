extends Node2D

const DURATION = { 'min': 0.5, 'max': 4.5 }
const DIST_FOR_MIN_INVINCIBILITY : float = 1400.0

var is_invincible : bool = false

onready var timer = $Timer
onready var body = get_parent().get_parent()
onready var anim_player = get_parent().get_node("AnimationPlayer")

func start(throwable):
	if body.modules.status.is_dead: return
	
	var dist = throwable.modules.distancetracker.last_throw_dist
	var ratio = (1.0 - min(dist / DIST_FOR_MIN_INVINCIBILITY, 1.0))
	var raw_duration = ratio * DURATION.max
	var duration = max(raw_duration, DURATION.min)
	
	if not GlobalDict.cfg.invincibility_depends_on_distance:
		duration = DURATION.max
	
	timer.wait_time = duration
	timer.start()
	
	is_invincible = true
	body.modules.topping.update_face()
	body.modules.particles.on_invincibility_start()

	# NOTE: Do not flicker the ALPHA, as that just makes everything (and especially the outline progress) look bad
	anim_player.play("Invincibility")

func stop():
	if body.modules.status.is_dead: return
	
	is_invincible = false
	body.modules.respawner.anim_player.stop()
	body.modulate.a = 1.0
	
	body.modules.topping.update_face()
	body.modules.particles.on_invincibility_end()
	anim_player.stop()

func _on_Timer_timeout():
	stop()

func disable(): 
	timer.stop()
	stop()
