extends Node2D

const MIN_THROWABLES : int = 3
const MAX_THROWABLES_PER_PLAYER : float = 2.5
var MAX_THROWABLES : int = -1

onready var map = get_node("/root/Main/Map")
onready var mode = get_node("/root/Main/ModeManager")
onready var powerups = get_node("/root/Main/Powerups")

var throwable_scene = preload("res://scenes/throwable.tscn")
var available_types = []
var full_list

var num_throwables : int = 0

func activate():
	full_list = GlobalDict.throwables
	available_types = GlobalDict.cfg.throwables
	
	MAX_THROWABLES = int(round(GlobalInput.get_player_count() * MAX_THROWABLES_PER_PLAYER))
	
	check_required_throwable_type()	
	precalculate_throwable_probabilities()

func check_required_throwable_type():
	var req_type = mode.required_throwable_type()
	var list_has_req_type = false
	if req_type:
		for type in available_types:
			if GlobalDict.throwables[type].category != req_type: continue
			list_has_req_type = true
			break
		
		if not list_has_req_type:
			available_types.append(req_type)

func precalculate_throwable_probabilities():
	var sum : float = 0.0
	for key in available_types:
		var weight = 1.0
		if full_list[key].has('prob'):
			weight = full_list[key].prob
		else:
			full_list[key].prob = 1.0
		
		sum += weight
	
	var running_sum : float = 0.0
	for key in available_types:
		running_sum += (full_list[key].prob / sum)
		full_list[key].weight = running_sum

func get_random_type():
	if available_types.size() <= 0: return null
	
	var target = randf()
	for key in available_types:
		if full_list[key].weight >= target:
			return key

func create_new_for(body, type, count_it = true):
	var t = create(type, count_it)
	t.modules.grabber.force_grab(body)

func create(type, count_it = true):
	var t = throwable_scene.instance()
	map.knives.add_child(t)
	t.modules.status.set_type(type)
	
	# NOTE: When a throwable POWERUP appears, we also count it as a throwable already (to prevent spawning loads of knife powerups when we seem low on knives)
	# Therefore, it must not be counted again when the powerup is picked up
	if count_it: change_count(1)
	return t

func change_count(val):
	num_throwables += val
	
	if num_throwables < MIN_THROWABLES:
		var params = {
			'make_knife': true,
			'immediate_slice': true
		}
		powerups.call_deferred("place_powerup", 0, params)

func _on_Timer_timeout():
	remove_throwables_if_too_many()

func remove_throwables_if_too_many():
	var all_throwables = get_tree().get_nodes_in_group("Throwables")
	var num_throwables = all_throwables.size()
	if num_throwables <= MAX_THROWABLES: return
	
	for i in range(num_throwables-1,-1,-1):
		var p = all_throwables[i]
		if not p.is_in_group("Knives"): continue
		
		# if not stuck, it's either being held, or busy with an active throw
		# (for consistency, knives that just fizzle out and come to a standstill, are also considered "stuck")
		if not p.modules.status.is_stuck: continue
		
		p.modules.status.delete()
		num_throwables -= 1
		if num_throwables <= MAX_THROWABLES: break
