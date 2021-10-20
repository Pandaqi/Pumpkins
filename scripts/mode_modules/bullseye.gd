extends Node

const NUMBERS = { 'min': 1, 'max': 3 }
const SPAWN_TIMES = { 'min': 5.0, 'max': 10.0 }
const TARGET_SIZE : float = 64.0 # 0.5*128
const MIN_DIST_TO_PLAYER : float = 100.0
const MIN_DIST_TO_OTHER_TARGET : float = 200.0

onready var timer = $Timer
onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")

var target_scene = preload("res://scenes/mode_modules/target.tscn")

var placement_params

func activate():
	placement_params = { 
		"body_radius": 0.5*TARGET_SIZE, 
		"avoid_players": MIN_DIST_TO_PLAYER,
		"avoid_targets": MIN_DIST_TO_OTHER_TARGET
	}
	
	_on_Timer_timeout()

func get_random_time():
	return rand_range(SPAWN_TIMES.min, SPAWN_TIMES.max)

func _on_Timer_timeout():
	check_target_placement()
	
	timer.wait_time = get_random_time()
	timer.start()

func check_target_placement():
	var num_targets = get_tree().get_nodes_in_group("Targets")
	if num_targets.size() >= NUMBERS.max: return
	
	place_target()

func place_target():
	var p = target_scene.instance()
	p.set_position(spawner.get_valid_pos(placement_params))
	p.set_rotation(randf() * 2 * PI)
	map.add_child(p)
