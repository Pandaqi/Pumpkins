extends Node

var game_mode : String
var mode_data 
var min_collections_needed_to_win : int = 5

func activate():
	game_mode = GlobalDict.cfg.game_mode 
	mode_data = GlobalDict.modes[game_mode]
	
	if mode_data.has('auto_spawns'):
		var module = load("res://scenes/mode_modules/" + mode_data.auto_spawns + ".tscn").instance()
		add_child(module)
		module.activate()

func win_type_is(tp):
	return mode_data.win == tp

func can_eat_player_parts():
	return mode_data.has('eat_player_parts')

func can_slice_players():
	return not mode_data.has('forbid_slicing_players')

func get_target_number():
	if not mode_data.has("target_num"): return -1
	return mode_data.target_num

func does_rubble_fade():
	return mode_data.has('fade_rubble')

func auto_grow_players():
	return mode_data.has('auto_grow')

func get_player_slicing_penalty():
	if not mode_data.has('player_slicing_penalty'): return 0
	return mode_data.player_slicing_penalty
