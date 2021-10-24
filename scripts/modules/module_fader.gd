extends Node

const FADE_DURATION : float = 11.0
onready var timer = $Timer
onready var body = get_parent()

onready var mode = get_node("/root/Main/ModeManager")
var has_self_destructed : bool = false

func _ready():
	if not mode.does_rubble_fade():
		self_destruct()
		return
	
	timer.wait_time = FADE_DURATION
	timer.start()

# NOTE: if we don't ensure a minimum value greater than 0,
# there will be some time where the thing is _practically invisible_ but still influences game state
# which isn't ideal
func _physics_process(_dt):
	if has_self_destructed: return
	body.modulate.a = clamp(timer.time_left / FADE_DURATION, 0.1, 1.0)

func _on_Timer_timeout():
	body.queue_free()

func self_destruct():
	body.modules.fader = null
	has_self_destructed = true
	self.queue_free()
