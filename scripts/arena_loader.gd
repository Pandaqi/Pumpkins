extends Node

var arena = "graveyard"

onready var map = get_node("/root/Main/Map")

func activate():
	load_arena()

func load_arena():
	var scene = load("res://arenas/" + arena + ".tscn").instance()
	
	for child in scene.get_children():
		if child.name == "Map":
			for new_child in child.get_children():
				new_child.get_parent().remove_child(new_child)
				map.get_node(new_child.name).add_child(new_child)
	
