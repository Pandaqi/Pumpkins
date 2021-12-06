extends Node

const NUMBERS = { 'min': 1, 'max': 5 }
const SPAWN_TIMES = { 'min': 2.0, 'max': 5.0 }
const POWERUP_SIZE : float = 64.0 # 0.5*128
const MIN_DIST_TO_PLAYER : float = 100.0
const MIN_DIST_TO_OTHER_POWERUP : float = 200.0

const POWERUP_IS_THROWABLE_PROB : float = 0.4

onready var timer = $Timer
onready var tween = $Tween
onready var map = get_node("/root/Main/Map")
onready var shape_manager = get_node("/root/Main/ShapeManager")
onready var spawner = get_node("/root/Main/Spawner")
onready var throwables = get_node("/root/Main/Throwables")
onready var mode = get_node("/root/Main/ModeManager")

onready var auto_reveal_timer = $AutoRevealTimer
var forced_slices = []

var powerup_scene = preload("res://scenes/powerup.tscn")

var available_powerups = []
var full_list = []
var pre_locs = null
var placement_params

var spawns_since_last_req_type : int = 0

func activate():
	available_powerups = GlobalDict.cfg.powerups
	placement_params = { 
		"body_radius": 0.5*POWERUP_SIZE, 
		"avoid_players": MIN_DIST_TO_PLAYER,
		"avoid_powerups": MIN_DIST_TO_OTHER_POWERUP
	}
	
	pre_locs = GlobalDict.cfg.predefined_powerup_locations
	
	precalculate_powerup_probabilities()
	_on_Timer_timeout()


func precalculate_powerup_probabilities():
	var ps = GlobalDict.powerups
	var sum : float = 0.0
	for key in available_powerups:
		var weight = 1.0
		if ps[key].has('prob'):
			weight = ps[key].prob
		else:
			ps[key].prob = 1.0
		
		sum += weight
	
	var running_sum : float = 0.0
	for key in available_powerups:
		running_sum += (ps[key].prob / sum)
		ps[key].weight = running_sum

func get_random_time():
	return rand_range(SPAWN_TIMES.min, SPAWN_TIMES.max)

func _on_Timer_timeout():
	check_powerup_placement()
	
	timer.wait_time = get_random_time()
	timer.start()

func check_powerup_placement():
	var num_powerups = get_tree().get_nodes_in_group("Powerups").size()
	if num_powerups >= NUMBERS.max: return
	if pre_locs and num_powerups >= pre_locs.size(): return
	
	place_powerup(num_powerups)

func get_random_type():
	if available_powerups.size() <= 0: return null 
	
	var target = randf()
	for key in available_powerups:
		if GlobalDict.powerups[key].weight >= target:
			return key

func place_powerup(cur_num_powerups = 0, forced_params = {}):
	var not_initialized_yet = (not placement_params)
	if not_initialized_yet: return
	
	var p = powerup_scene.instance()
	
	var pos = spawner.get_valid_pos(placement_params)
	if pre_locs: pos = pre_locs[randi() % pre_locs.size()]
	if pre_locs and cur_num_powerups <= 0: pos = pre_locs[0]
	
	p.set_position(pos)
	p.set_rotation(randf() * 2 * PI)
	map.knives.add_child(p)
	
	var is_throwable = (randf() <= POWERUP_IS_THROWABLE_PROB)
	
	var rand_type = get_random_type()
	if not rand_type: is_throwable = true
	
	if is_throwable: rand_type = throwables.get_random_type()
	if not rand_type: rand_type = "knife" # if all else fails, default to just giving more knives
	
	var params = check_required_type(rand_type, is_throwable)
	
	if forced_params.has('make_knife'):
		params.is_throwable = true
		params.rand_type = 'knife'

	p.set_throwable(params.is_throwable)
	p.set_type(params.rand_type)
	
	var rand_shape = shape_manager.get_random_shape()
	p.set_shape(rand_shape)
	
	tween_bounce_appear(p)
	
	if forced_params.has('immediate_slice'):
		auto_reveal_timer.wait_time = 0.2
		auto_reveal_timer.start()
		forced_slices.append(p)

func check_required_type(rand_type, is_throwable):
	var params = {
		'rand_type': rand_type,
		'is_throwable': is_throwable,
	}
	
	var req_type = mode.required_throwable_type()
	if not req_type: return params
	
	if spawns_since_last_req_type > 3:
		spawns_since_last_req_type = 0
		
		params.rand_type = req_type
		params.is_throwable = true
		return params
	
	if not is_throwable: 
		spawns_since_last_req_type += 1
		return params
	
	if GlobalDict.throwables[rand_type].category != req_type:
		spawns_since_last_req_type += 1
		return params
	
	spawns_since_last_req_type = 0
	return params

func tween_bounce_appear(obj):
	var start_scale = Vector2.ZERO
	var target_scale = Vector2(1,1)
	
	tween.interpolate_property(obj, "scale", 
		start_scale, target_scale, 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(obj, "rotation", 
		0, 2*PI, 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.start()

func tween_revealed_powerup(obj):
	tween.interpolate_property(obj, "scale",
	obj.get_scale()*0.75, obj.get_scale(), 0.5,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(obj, "rotation",
	0, 2*PI, 0.2,
	Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func _on_AutoRevealTimer_timeout():
	var ps = get_tree().get_nodes_in_group("PowerupsUnrevealed")
	if ps.size() <= 0: return
	if not GlobalDict.cfg.auto_slice_powerups: return

	if forced_slices.size() > 0:
		for s in forced_slices:
			if not s or not is_instance_valid(s): continue
			s.auto_slice()
		forced_slices = []
		return
	
	var rand_powerup = ps[randi() % ps.size()]
	rand_powerup.auto_slice()
