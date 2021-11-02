extends Node

var hole_scene = preload("res://scenes/arenas/haunted_house/hole.tscn")

onready var map = get_node("/root/Main/Map")
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
	
	# TO DO: invoke spawner, ensure minimum distance from players or other holes
	var rand_pos = Vector2(randf(), randf())*Vector2(1920,1080)
	h.set_position(rand_pos)
	
	map.bg.add_child(h)
	
	wall.bodies_created.append(h)
	
	
