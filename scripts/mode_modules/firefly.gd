extends KinematicBody2D

const SPEED : float = 100.0
const EDGE_MARGIN : float = 180.0
const PAUSE_PROBABILITY : float = 0.1

onready var timer : Timer = $Timer
onready var light : Light2D = $Light2D
var vec : Vector2 = Vector2.ZERO

onready var light_timer : Timer = $LightTimer

var owned : bool = false
var my_owner

func _ready():
	_on_Timer_timeout()

func _physics_process(_dt):
# warning-ignore:return_value_discarded
	move_and_slide(vec * SPEED)
	set_rotation(vec.angle())
	light.energy = 1.2 + (randf()-0.5)*0.14

func on_throwable_hit():
	lights_out()

func is_owned():
	return owned

func set_owner(body):
	my_owner = body
	owned = true
	
	body.modules.status.hide_completely()
	body.modules.input.connect("move_vec", self, "receive_vec")

func receive_vec(new_vec, _dt = 0.016):
	vec = new_vec

func lights_out():
	light.set_visible(false)
	light_timer.start()

func _on_Timer_timeout():
	change_direction()
	
	timer.wait_time = 1.0 + randf()*4.0
	timer.start()

func change_direction():
	var rot = 2*PI*randf()
	vec = Vector2(cos(rot), sin(rot))
	
	# keep within bounds
	var pos = get_global_position()
	if pos.x < EDGE_MARGIN:
		vec.x = 1
	elif pos.x > 1920 - EDGE_MARGIN:
		vec.x = -1
	
	if pos.y < EDGE_MARGIN:
		vec.y = 1
	elif pos.y > 1080 - EDGE_MARGIN:
		vec.y = -1
	
	vec = vec.normalized()
	
	if randf() <= PAUSE_PROBABILITY:
		vec = Vector2.ZERO

func _on_LightTimer_timeout():
	light.set_visible(true)
