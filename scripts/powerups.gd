extends Node

const NUMBERS = { 'min': 1, 'max': 5 }
const SPAWN_TIMES = { 'min': 2.0, 'max': 5.0 }
const POWERUP_SIZE : float = 64.0 # 0.5*128
const MIN_DIST_TO_PLAYER : float = 100.0
const MIN_DIST_TO_OTHER_POWERUP : float = 200.0

onready var timer = $Timer
onready var map = get_node("/root/Main/Map")
onready var shape_manager = get_node("/root/Main/ShapeManager")
onready var spawner = get_node("/root/Main/Spawner")

var powerup_scene = preload("res://scenes/powerup.tscn")

var available_powerups = []
var placement_params

func activate():
	available_powerups = GlobalDict.powerups.keys()
	placement_params = { 
		"body_radius": 0.5*POWERUP_SIZE, 
		"avoid_players": MIN_DIST_TO_PLAYER,
		"avoid_powerups": MIN_DIST_TO_OTHER_POWERUP
	}
	
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
	var num_powerups = get_tree().get_nodes_in_group("Powerups")
	if num_powerups.size() >= NUMBERS.max: return
	
	place_powerup()

func get_random_type():
	var target = randf()
	for key in available_powerups:
		if GlobalDict.powerups[key].weight >= target:
			return key

func place_powerup():
	var p = powerup_scene.instance()
	p.set_position(spawner.get_valid_pos(placement_params))
	p.set_rotation(randf() * 2 * PI)
	map.knives.add_child(p)
	
	var rand_type = get_random_type()
	p.set_type(rand_type)
	
	var rand_shape = shape_manager.get_random_shape()
	p.set_shape(rand_shape)
