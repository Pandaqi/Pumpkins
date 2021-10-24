extends Node

const FADE_DURATION : float = 11.0
onready var timer = $Timer
onready var body = get_parent()

onready var mode = get_node("/root/Main/ModeManager")
var has_self_destructed : bool = false

func activate(is_from_player : bool):
	if not mode.does_rubble_fade():
		if is_from_player:
			self_destruct()
			return
	
	timer.wait_time = FADE_DURATION
	timer.start()

func _physics_process(_dt):
	if has_self_destructed: return

	body.modulate.a = clamp(timer.time_left / FADE_DURATION, 0.0, 1.0)

func _on_Timer_timeout():
	body.queue_free()

func self_destruct():
	body.modules.fader = null
	has_self_destructed = true
	self.queue_free()
