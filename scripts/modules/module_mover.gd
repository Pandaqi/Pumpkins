extends Node

const MOVE_SPEED : float = 400.0
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
