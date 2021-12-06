extends Node

const NUM_MIRRORS : int = 12

var mirror_scene = preload("res://scenes/arenas/haunted_house/mirror.tscn")

onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")
onready var wall = get_parent()

func activate():
	for i in range(NUM_MIRRORS):
		place_mirror()

func deactivate():
	pass

func place_mirror():
	var m = mirror_scene.instance()
	
	var params = {
		'body_radius': 30,
		'avoid_group': "Mirrors",
		'avoid_group_dist': 130.0
	}
	var rand_pos = spawner.get_valid_pos(params)
	m.set_position(rand_pos)
	
	var rand_rot = (randi() % 8) * 0.25 * PI
	m.set_rotation(rand_rot)

	map.entities.add_child(m)
	
	wall.register_body(m)
