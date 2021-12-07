extends Node2D

const TIMER = { 'min': 6.0, 'max': 12.0 }
const NUM_TUTORIAL_STONES = 4

onready var timer = $Timer

var stone_scene = preload("res://scenes/arenas/training_ravines/training_stone.tscn")
var stones = []

onready var map = get_node("/root/Main/Map")
onready var players = get_node("/root/Main/Players")

func activate():
	place_tutorial_stones()
	restart_timer()
	
	var num_teams = players.count_num_teams()
	if num_teams == 2:
		map.bg.get_node("DiagonalTwo").queue_free()
		map.bg.get_node("DiagonalThree").queue_free()
	elif num_teams == 3:
		map.bg.get_node("DiagonalThree").queue_free()

func on_player_death(_p) -> Dictionary:
	return {}

func place_tutorial_stones():
	for i in range(NUM_TUTORIAL_STONES):
		place_random_stone()

func get_pos_with_margin(margin : float = 50.0):
	return Vector2(randf()*(1920-margin*2) + margin, randf()*(1080-2*margin) + margin)

func place_random_stone():
	var s = stone_scene.instance()
	s.set_rotation(randf()*2*PI)
	s.set_position(get_pos_with_margin())
	s.set_scale(Vector2.ONE*0.75)
	map.entities.add_child(s)
	stones.append(s)

func remove_random_stone():
	stones.shuffle()
	var s = stones.pop_back()
	s.queue_free()

func _on_Timer_timeout():
	restart_timer()
	remove_random_stone()
	place_random_stone()

func restart_timer():
	timer.wait_time = rand_range(TIMER.min, TIMER.max)
	timer.start()
