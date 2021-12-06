extends Node

var hole_scene = preload("res://scenes/arenas/haunted_house/hole.tscn")

onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")

onready var timer = $Timer
onready var wall = get_parent()

func activate():
	_on_Timer_timeout()

func deactivate():
	timer.stop()

func _on_Timer_timeout():
	timer.start()
	place_hole()

func place_hole():
	var h = hole_scene.instance()

	var params = {
		'avoid_group': 'Holes',
		'avoid_group_dist': 150.0,
		'avoid_players': 150.0,
		'edge_margin': 200.0
	}
	var rand_pos = spawner.get_valid_pos(params)
	h.set_position(rand_pos)
	
	map.bg.add_child(h)
	
	wall.register_body(h)
	
	
