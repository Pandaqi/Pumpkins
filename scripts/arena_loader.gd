extends Node

var arena : String = "graveyard"

onready var main_node = get_node("/root/Main")
onready var map = get_node("/root/Main/Map")
onready var collectors = get_node("/root/Main/Collectors")

func activate():
	load_arena()

func load_arena():
	arena = GlobalDict.cfg.arena
	
	var scene = load("res://arenas/" + arena + ".tscn").instance()
	var custom_logic = null
	
	for child in scene.get_children():
		if child.name == "Map":
			for new_child in child.get_children():
				new_child.get_parent().remove_child(new_child)
				map.get_node(new_child.name).add_child(new_child)
		
		elif child.name == "Collectors":
			collectors.place(child)
		
		elif child.name == "CustomLogic":
			custom_logic = child
			child.get_parent().remove_child(child)
			main_node.add_child(child)
	
	if custom_logic and custom_logic.script:
		custom_logic.activate()
	
