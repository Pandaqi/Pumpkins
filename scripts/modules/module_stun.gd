extends Node2D

const DURATION = { 'min': 0.5, 'max': 3.0 }
const DIST_FOR_MAX_STUN : float = 1400.0
var is_stunned : bool = false

onready var outline_progress = $OutlineProgress
onready var timer = $Timer

onready var body = get_parent().get_parent()

func start(throwable):
	var dist = throwable.modules.distancetracker.last_throw_dist
	var ratio = min(dist / DIST_FOR_MAX_STUN, 1.0)
	var raw_duration = ratio * DURATION.max
	var duration = max(raw_duration, DURATION.min)
	
	if not GlobalDict.cfg.invincibility_depends_on_distance:
		duration = DURATION.max
	
	timer.wait_time = duration
	timer.start()
	
	is_stunned = true
	
	body.modules.knives.cancel_throw()
	
	outline_progress.start(body.modules.drawer.outline_polygon, duration)

func stop():
	is_stunned = false
	
	outline_progress.stop()

func _on_Timer_timeout():
	stop()
