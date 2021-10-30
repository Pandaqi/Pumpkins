extends Node2D

var last_throw_dist : float = 0.0
var throw_velocity : Vector2

onready var body = get_parent()

func reset():
	last_throw_dist = 0.0
	
	throw_velocity = body.modules.mover.get_velocity()

func calculate():
	return last_throw_dist

func get_original_velocity():
	return throw_velocity

func _on_Mover_move_complete(dist):
	last_throw_dist += dist
