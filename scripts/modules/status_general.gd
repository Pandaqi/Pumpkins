extends Node2D

var in_water : bool = false
var player_num : int = -1
var team_num : int = -1

var delete_audio_key : String = ""

onready var body = get_parent()

func enter_water():
	in_water = true

func exit_water():
	in_water = false

func react_to_areas():
	return true

func set_delete_audio(key):
	delete_audio_key = key

func delete(_attacking_throwable):
	if delete_audio_key != "":
		GlobalAudio.play_dynamic_sound(body, delete_audio_key)
	
	body.queue_free()

func is_from_a_player():
	return false
