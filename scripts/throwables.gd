extends Node2D

onready var map = get_node("/root/Main/Map")
onready var mode = get_node("/root/Main/ModeManager")

var throwable_scene = preload("res://scenes/throwable.tscn")
var available_types = []
var full_list

func activate():
	full_list = GlobalDict.throwables
	available_types = GlobalDict.cfg.throwables
	
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

func create_new_for(body, type):
	var t = create(type)
	t.modules.grabber.force_grab(body)

func create(type):
	var t = throwable_scene.instance()
	map.knives.add_child(t)
	t.modules.status.set_type(type)
	return t
