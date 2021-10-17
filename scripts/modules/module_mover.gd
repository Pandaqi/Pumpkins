extends Node

const MOVE_SPEED : float = 400.0

onready var body : KinematicBody2D = get_parent()

var moving_enabled : bool = true

func _on_Input_move_vec(vec : Vector2):
	if not moving_enabled: return
	if vec.length() <= 0.03: return
	
	body.slowly_orient_towards_vec(vec)
	
	var final_vec = body.get_forward_vec()*MOVE_SPEED
	body.move_and_slide(final_vec)

func _on_Input_button_press():
	moving_enabled = false

func _on_Input_button_release():
	moving_enabled = true
