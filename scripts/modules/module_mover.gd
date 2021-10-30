extends Node

const MOVE_SPEED : float = 320.0
const SLIDY_MOVEMENT_DAMPING : float = 0.996
var speed_multiplier : float = 1.0

onready var body : KinematicBody2D = get_parent()

var moving_enabled : bool = true
var reversed : bool = false
var ice : bool = false

var forward_vec = Vector2.RIGHT
var state = "stopped"

var last_velocity : Vector2
var move_audio_player = null

signal movement_stopped()
signal movement_started()

signal moved(amount)

func _on_Input_move_vec(vec : Vector2, _dt : float):
	if not moving_enabled and GlobalDict.cfg.use_slidy_throwing:
		continue_on_last_velocity()
		return
	
	if not moving_enabled or vec.length() <= 0.03: 
		if state != "stopped":
			remove_move_audio()
			emit_signal("movement_stopped")
		state = "stopped"
		last_velocity = Vector2.ZERO
		return
	
	if state == "stopped":
		state = "moving"
		emit_signal("movement_started")
	
	if reversed: vec *= -1
	
	move_regular(vec)
	
	if not move_audio_player or not is_instance_valid(move_audio_player):
		move_audio_player = GlobalAudio.play_dynamic_sound(body, "move", -9)

func remove_move_audio():
	if not move_audio_player: return
	if not is_instance_valid(move_audio_player): 
		move_audio_player = null
		return
	
	move_audio_player.queue_free()
	move_audio_player = null

func continue_on_last_velocity():
# warning-ignore:return_value_discarded
	body.move_and_slide(last_velocity)
	last_velocity *= SLIDY_MOVEMENT_DAMPING

func move_regular(vec):
	body.slowly_orient_towards_vec(vec)
	
	var in_water = body.modules.status.in_water
	var lerp_factor = 1.0
	if in_water: lerp_factor = 0.0124
	if ice: lerp_factor = 0.007
	
	forward_vec = lerp(forward_vec, body.get_forward_vec(), lerp_factor)
	
	var speed_penalty_for_size = body.modules.shaper.get_size_as_ratio()*0.5 + 0.5
	var speed_penalty_water = 1.0
	if in_water: speed_penalty_water = 0.5
	
	var final_speed = speed_multiplier*MOVE_SPEED*speed_penalty_for_size*speed_penalty_water
	var final_vec = forward_vec*final_speed
	
	var old_pos = body.get_global_position()
	
# warning-ignore:return_value_discarded
	var result_vec = body.move_and_slide(final_vec, Vector2.ZERO)
#
#	if body.modules.status.is_bot:
#		body.move_and_slide(result_vec)
	
	last_velocity = final_vec
	
	var new_pos = body.get_global_position()
	var dist_moved = (new_pos - old_pos)
	
	body.modules.statistics.record("total_distance", dist_moved.length())
	
	emit_signal("moved", dist_moved)

func _on_Input_button_press():
	moving_enabled = false

func _on_Input_button_release():
	moving_enabled = true

func change_speed_multiplier(val):
	speed_multiplier = clamp(speed_multiplier*val, 0.2, 3.0)

func get_speed_with_delta(dt):
	return speed_multiplier*MOVE_SPEED*dt
