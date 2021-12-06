extends Node

var boulder_scene = preload("res://scenes/arenas/haunted_house/boulder.tscn")

onready var wall = get_parent()
onready var map = get_node("/root/Main/Map")

onready var timer = $Timer

func activate():
	_on_Timer_timeout()

func deactivate():
	timer.stop()

func _on_Timer_timeout():
	timer.start()
	shoot_boulder()

func shoot_boulder():
	var b = boulder_scene.instance()
	
	var margin = 20
	var rand_pos = Vector2(1920, randf() * (1080-2*margin) + margin)
	b.set_position(rand_pos)
	b.set_direction(Vector2.LEFT)
	map.entities.add_child(b)
	
	wall.register_body(b)
