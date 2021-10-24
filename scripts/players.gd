extends Node

const DEFAULT_PLAYER_RADIUS : float = 25.0
const MIN_DIST_BETWEEN_PLAYERS : float = 200.0

var num_players
var player_scene = preload("res://scenes/player.tscn")

onready var main_node = get_parent()
onready var map = get_node("../Map")
onready var spawner = get_node("../Spawner")
onready var mode = get_node("../ModeManager")
onready var shape_manager = get_node("../ShapeManager")
onready var particles = get_node("../Particles")
onready var collectors = get_node("../Collectors")

func activate():
	create_players()
	show_team_reminders()

func create_players():
	var max_players = GlobalDict.cfg.max_players
	
	var params = { 
		'body_radius': DEFAULT_PLAYER_RADIUS, 
		'avoid_players': MIN_DIST_BETWEEN_PLAYERS 
	}
	
	var player_data = GlobalDict.player_data
	
	for i in range(max_players):
		if not player_data[i].active: break

		var p = player_scene.instance()
		
		if player_data[i].bot:
			p.get_node("Status").turn_into_bot()
		else:
			p.get_node("Status").turn_into_player()
		
		map.entities.add_child(p)
		
		p.set_position(spawner.get_valid_pos(params))
		
		var new_shape = shape_manager.select_random_predefined_shape()
		if GlobalDict.cfg.everyone_starts_pumpkin:
			new_shape = shape_manager.select_random_pumpkin_shape()
		
		p.modules.shaper.create_from_shape(new_shape)
		p.modules.status.set_player_num(i)
		p.modules.status.set_team_num(player_data[i].team)

		if not mode.can_slice_players():
			p.remove_from_group("Sliceables")
		
		p.set_rotation(randf()*2*PI)
	
	collectors.show_player_icons()

func show_team_reminders():
	for i in range(8):
		var players = get_players_in_team(i)
		if players.size() <= 1: continue
		
		for p in players:
			particles.place_team_reminder(p.get_global_position(), i)

func get_players_in_team(team_num):
	var players = get_tree().get_nodes_in_group("Players")
	var arr = []
	for p in players:
		if p.modules.status.team_num != team_num: continue
		arr.append(p)
	return arr

func get_closest_to(pos, ignore = []):
	var players = get_tree().get_nodes_in_group("Players")

	var best_match = null
	var best_dist = INF
	for p in players:
		var dist = (p.get_global_position() - pos).length()
		if dist > best_dist: continue
		if p in ignore: continue
		
		best_dist = dist
		best_match = p
	
	return best_match

func get_all_within_range(pos, radius):
	var players = get_tree().get_nodes_in_group("Players")
	var arr = []
	for p in players:
		var dist = (p.get_global_position() - pos).length()
		if dist > radius: continue
		
		arr.append(p)
	
	return arr
	
	
	
	
	
	
	
	
