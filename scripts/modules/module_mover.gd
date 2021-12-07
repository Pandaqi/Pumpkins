extends Node

const MOVE_SPEED : float = 300.0
const SLIDY_MOVEMENT_DAMPING : float = 0.996
var speed_multiplier : float = 1.0

onready var body : KinematicBody2D = get_parent()
onready var players = get_node("/root/Main/Players")

var moving_enabled : bool = true
var force_move_override : bool = false

var reversed : bool = false
var ice : bool = false

var forward_vec = Vector2.RIGHT
var state = "stopped"

var last_velocity : Vector2
var move_audio_player = null

var ideal_movement_per_frame

# what distance constitutes "being too nearby/close another player"
const NEARBY_DIST : float = 270.0

signal movement_stopped()
signal movement_started()

signal moved(amount)

func _on_Input_move_vec(vec : Vector2, dt : float):
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
	
	move_regular(vec, dt)
	
	if not move_audio_player or not is_instance_valid(move_audio_player):
		create_move_audio()

func recreate_move_audio():
	remove_move_audio()
	create_move_audio()

func create_move_audio():
	var key = "move"
	if body.modules.status.in_water: key = "move_water"
	
	move_audio_player = GlobalAudio.play_dynamic_sound(body, key, -9)

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

func move_regular(vec, dt):
	var look_where_were_going = true
	if GlobalDict.cfg.use_control_scheme_with_constant_moving and not body.modules.status.is_bot:
		if body.modules.slasher.slashing_enabled:
			look_where_were_going = false
	
	if look_where_were_going:
		body.slowly_orient_towards_vec(vec)
	
	var in_water = body.modules.status.in_water
	var lerp_factor = 1.0
	if in_water: lerp_factor = 0.0124
	if ice: lerp_factor = 0.007
	
	if look_where_were_going:
		forward_vec = lerp(forward_vec, body.get_forward_vec(), lerp_factor)
	else:
		forward_vec = body.get_forward_vec()
	
	var speed_penalty_for_size = 1.0
	if GlobalDict.cfg.move_faster_if_big:
		body.modules.shaper.get_size_as_ratio()*0.5 + 0.5
	
	var speed_penalty_water = 1.0
	if in_water: speed_penalty_water = 0.775
	
	var speed_bonus_for_being_close = 1.0
	if GlobalDict.cfg.move_faster_if_close:
		var closest_player = players.get_closest_to(body.global_position, players.get_players_in_team(body.modules.status.team_num))
		if closest_player and (closest_player.global_position - body.global_position).length() <= NEARBY_DIST:
			speed_bonus_for_being_close = 1.66
		
	var final_speed = speed_multiplier*MOVE_SPEED*speed_penalty_for_size*speed_penalty_water*speed_bonus_for_being_close
	var final_vec = forward_vec
	if not look_where_were_going: final_vec = vec.normalized()
	
	var final_move_in_pixels = final_vec * final_speed
	
	ideal_movement_per_frame = (final_move_in_pixels * dt).length()
	
	var old_pos = body.get_global_position()
	
# warning-ignore:return_value_discarded
	var result_vec = body.move_and_slide(final_move_in_pixels, Vector2.ZERO)
#
#	if body.modules.status.is_bot:
#		body.move_and_slide(result_vec)
	
	last_velocity = final_move_in_pixels
	
	var new_pos = body.get_global_position()
	var dist_moved = (new_pos - old_pos)
	
	body.modules.statistics.record("total_distance", dist_moved.length())
	
	emit_signal("moved", dist_moved)

func disable():
	moving_enabled = false

func enable():
	moving_enabled = true

func force_disable():
	force_move_override = true
	last_velocity = Vector2.ZERO
	disable()

func force_enable():
	force_move_override = false
	enable()

func _on_Input_button_press():
	if force_move_override: return
	if GlobalDict.cfg.use_control_scheme_with_constant_moving and not body.modules.status.is_bot: return
	disable()

func _on_Input_button_release():
	if force_move_override: return
	if GlobalDict.cfg.use_control_scheme_with_constant_moving and not body.modules.status.is_bot: return
	enable()

func change_speed_multiplier(val):
	speed_multiplier = clamp(speed_multiplier*val, 0.2, 3.0)

func get_speed_with_delta(dt):
	return speed_multiplier*MOVE_SPEED*dt
