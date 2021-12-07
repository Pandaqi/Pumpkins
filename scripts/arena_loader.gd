extends Node

var arena : String = "graveyard"
var arena_data

onready var main_node = get_node("/root/Main")
onready var map = get_node("../Map")
onready var players = get_node("../Players")
onready var collectors = get_node("../Collectors")

var huge_dumpling_scene = preload("res://scenes/mode_modules/huge_dumpling.tscn")

var custom_logic = null
var dumpling_locations = []
var huge_dumplings = []

var teams_to_locations = {}
var predefined_locations = []

func activate():
	load_arena()

func load_arena():
	arena = GlobalDict.cfg.arena
	
	var scene = load("res://arenas/" + arena + ".tscn").instance()
	custom_logic = null
	
	for child in scene.get_children():
		if child.name == "Map":
			for new_child in child.get_children():
				for new_new_child in new_child.get_children():
					new_new_child.get_parent().remove_child(new_new_child)
					map.get_node(new_child.name).add_child(new_new_child)
		
		elif child.name == "Collectors":
			for collec in child.get_children():
				predefined_locations.append(collec)
			collectors.place(child)
		
		elif child.name == "CustomLogic":
			custom_logic = child
			child.get_parent().remove_child(child)
			main_node.add_child(child)
		
		elif child.name == "Dumplings":
			record_dumpling_locations(child)
	
	if custom_logic and custom_logic.script:
		custom_logic.activate()
	
	arena_data = GlobalDict.arenas[arena]
	
	if arena_data.has('num_starting_knives'):
		GlobalDict.cfg.num_starting_knives = arena_data.num_starting_knives
	
	if GlobalDict.cfg.game_mode == "dwarfing_dumplings":
		place_huge_dumplings()
	
	# some modes must place teams at specific locations, so calculate them in advance
	assign_teams_to_locations()

func assign_teams_to_locations():
	var cur_loc = 0
	for i in range(8):
		for a in range(8):
			if not GlobalDict.player_data[a].active: continue
			if not GlobalDict.player_data[a].team == i: continue
			
			teams_to_locations[i] = cur_loc
			cur_loc += 1
			break

func on_player_death(p):
	return custom_logic.on_player_death(p)

func record_dumpling_locations(obj):
	for new_child in obj.get_children():
		dumpling_locations.append(new_child.position)

func place_huge_dumplings():
	var num_to_place = min(dumpling_locations.size(), players.count_num_teams())
	
	for i in range(num_to_place):
		var d = huge_dumpling_scene.instance()
		d.set_position(dumpling_locations[i])
		map.entities.add_child(d)
		
		d.modules.status.set_team_num(i)
		huge_dumplings.append(d)

func get_ghost_part_target_num():
	if not arena_data.has('ghost_part_target'): return -1
	return arena_data.ghost_part_target

func get_special_starting_pos(team_num):
	if not arena_data.has('special_starting_positions'): return null
	
	var node_num = teams_to_locations[team_num]
	var node = predefined_locations[node_num]
	
	var rand_rad = rand_range(20,60)
	var rand_ang = 2*randf()*PI
	
	return node.position + Vector2(cos(rand_ang), sin(rand_ang))*rand_rad
