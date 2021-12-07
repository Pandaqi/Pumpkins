extends Node2D

var is_reloading : bool = false

const RELOAD_DURATION : float = 3.0

onready var timer = $Timer
onready var outline_progress = $OutlineProgress
onready var body = get_parent().get_parent()

func on_throw():
	# reloading as a ghost is both pointless and ugly
	if body.modules.status.is_ghost: return
	
	is_reloading = true
	
	timer.wait_time = RELOAD_DURATION
	timer.start()
	outline_progress.start(body.modules.drawer.outline_polygon, RELOAD_DURATION)

func _on_Timer_timeout():
	is_reloading = false
	
	outline_progress.stop()
