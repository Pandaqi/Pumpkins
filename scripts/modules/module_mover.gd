extends Node

const MOVE_SPEED : float = 400.0
const ALT_ROTATE_SPEED : float = 0.5*0.016
var speed_multiplier : float = 1.0

onready var body : KinematicBody2D = get_parent()

var moving_enabled : bool = true
var reversed : bool = false
var ice : bool = false

var forward_vec = Vector2.RIGHT
var state = "stopped"

var last_velocity : Vector2

signal movement_stopped()
signal movement_started()

func _on_Input_move_vec(vec : Vector2):
	if not moving_enabled or vec.length() <= 0.03: 
		state = "stopped"
		emit_signal("movement_stopped")
		return
	
	if state == "stopped":
		state = "moving"
		emit_signal("movement_started")
	
	if reversed: vec *= -1
	
	if GlobalDict.cfg.use_alternate_control_scheme:
		move_alternate(vec)
	else:
		move_regular(vec)

func move_alternate(vec):
	if abs(vec.x) > 0.5:
		var rotate_dir = 1 if vec.x > 0 else -1
		body.rotate(rotate_dir*(2*PI)*ALT_ROTATE_SPEED)
	
	if abs(vec.y) > 0.5:
		var move_dir = 1 if vec.y < 0 else -1
		body.move_and_slide(body.get_forward_vec()*speed_multiplier*MOVE_SPEED*move_dir)

func move_regular(vec):
	body.slowly_orient_towards_vec(vec)
	
	var lerp_factor = 1.0
	if ice: lerp_factor = 0.1
	forward_vec = lerp(forward_vec, body.get_forward_vec(), lerp_factor)
	
	var final_vec = forward_vec*speed_multiplier*MOVE_SPEED
	body.move_and_slide(final_vec)
	
	last_velocity = final_vec

func _on_Input_button_press():
	moving_enabled = false

func _on_Input_button_release():
	moving_enabled = true

func change_speed_multiplier(val):
	speed_multiplier = clamp(speed_multiplier*val, 0.2, 3.0)

func get_speed_with_delta(dt):
	return speed_multiplier*MOVE_SPEED*dt
