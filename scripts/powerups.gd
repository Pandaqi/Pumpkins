extends Node

const SPAWN_TIMES = { 'min': 2.0, 'max': 5.0 }

onready var timer = $Timer
onready var map = get_node("/root/Main/Map")

var powerup_scene = preload("res://scenes/powerup.tscn")

var available_powerups = []

func activate():
	available_powerups = GlobalDict.powerups.keys()
	_on_Timer_timeout()

func get_random_time():
	return rand_range(SPAWN_TIMES.min, SPAWN_TIMES.max)

func _on_Timer_timeout():
	check_powerup_placement()
	
	timer.wait_time = get_random_time()
	timer.start()

func check_powerup_placement():
	place_powerup()

func get_random_type():
	return available_powerups[randi() % available_powerups.size()]

func place_powerup():
	var p = powerup_scene.instance()
	p.set_position(Vector2(randf(), randf())*Vector2(1920,1080))
	map.add_child(p)
	
	var rand_type = get_random_type()
	p.set_type(rand_type)
