extends Node2D

var mist_scene = preload("res://arenas/mist_scene.tscn")

func activate():
	pass

func on_player_death(p) -> Dictionary:
	var m = mist_scene.instance()
	p.add_child(m)
	m.position = Vector2.ZERO
	p.add_to_group("Mist")
	return {}
