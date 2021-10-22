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

signal moved(amount)

func _on_Input_move_vec(vec : Vector2):
	if not moving_enabled and GlobalDict.cfg.use_slidy_throwing:
		continue_on_last_velocity()
		return
	
	if not moving_enabled or vec.length() <= 0.03: 
		if state != "stopped": emit_signal("movement_stopped")
		state = "stopped"
		return
	
	if state == "stopped":
		state = "moving"
		emit_signal("movement_started")
	
	if reversed: vec *= -1
	
	move_regular(vec)

func continue_on_last_velocity():
	body.move_and_slide(last_velocity)

func move_regular(vec):
	body.slowly_orient_towards_vec(vec)
	
	var lerp_factor = 1.0
	if ice: lerp_factor = 0.1
	forward_vec = lerp(forward_vec, body.get_forward_vec(), lerp_factor)
	
	var speed_penalty_for_size = body.modules.shaper.get_size_as_ratio()*0.5 + 0.5
	var final_speed = speed_multiplier*MOVE_SPEED*speed_penalty_for_size
	var final_vec = forward_vec*final_speed
	var old_pos = body.get_global_position()
	body.move_and_slide(final_vec)
	
	last_velocity = final_vec
	
	var new_pos = body.get_global_position()
	emit_signal("moved", (new_pos - old_pos))

func _on_Input_button_press():
	moving_enabled = false

func _on_Input_button_release():
	moving_enabled = true

func change_speed_multiplier(val):
	speed_multiplier = clamp(speed_multiplier*val, 0.2, 3.0)

func get_speed_with_delta(dt):
	return speed_multiplier*MOVE_SPEED*dt
