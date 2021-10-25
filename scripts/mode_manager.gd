extends Node

const DEFAULT_MAX_KNIVES : int = 4

var game_mode : String
var mode_data 
var min_collections_needed_to_win : int = 5

onready var arena = get_node("../ArenaLoader")

func activate():
	game_mode = GlobalDict.cfg.game_mode 
	mode_data = GlobalDict.modes[game_mode]
	
	if mode_data.has('auto_spawns'):
		var module = load("res://scenes/mode_modules/" + mode_data.auto_spawns + ".tscn").instance()
		add_child(module)
		module.activate()
	
	if mode_data.has('num_starting_knives'):
		GlobalDict.cfg.num_starting_knives = mode_data.num_starting_knives

func has_collectibles():
	return mode_data.has("collectible_group")

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

func players_can_die():
	return mode_data.has("players_can_die")

func get_targets():
	var target_group = "Players"
	if mode_data.has('target_group'): target_group = mode_data.target_group
	return get_tree().get_nodes_in_group(target_group)

func get_collectibles():
	if not mode_data.has("collectible_group"): return []
	return get_tree().get_nodes_in_group(mode_data.collectible_group)

func get_max_knife_capacity():
	if not mode_data.has("max_knife_capacity"): return DEFAULT_MAX_KNIVES
	return mode_data.max_knife_capacity

func get_starting_knives():
	if not mode_data.has('num_starting_knives'): return GlobalDict.cfg.num_starting_knives
	return mode_data.num_starting_knives
