extends Node

const NUMBERS = { 'min': 1, 'max': 5 }
const SPAWN_TIMES = { 'min': 2.0, 'max': 5.0 }
const POWERUP_SIZE : float = 64.0 # 0.5*128
const MIN_DIST_TO_PLAYER : float = 100.0

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
		"avoid_players": MIN_DIST_TO_PLAYER 
	}
	
	_on_Timer_timeout()

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
	return available_powerups[randi() % available_powerups.size()]

func place_powerup():
	var p = powerup_scene.instance()
	p.set_position(spawner.get_valid_pos(placement_params))
	p.set_rotation(randf() * 2 * PI)
	map.add_child(p)
	
	var rand_type = get_random_type()
	p.set_type(rand_type)
	
	var rand_shape = shape_manager.get_random_shape()
	p.set_shape(rand_shape)
