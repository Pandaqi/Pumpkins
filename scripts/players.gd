extends Node

const DEFAULT_PLAYER_RADIUS : float = 25.0
const MIN_DIST_BETWEEN_PLAYERS : float = 200.0

var num_players
var player_scene = preload("res://scenes/player.tscn")

onready var main_node = get_parent()
onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")
onready var shape_manager = get_node("/root/Main/ShapeManager")

func activate():
	create_players()

func create_players():
	var max_players = 6
	
	var params = { 'body_radius': DEFAULT_PLAYER_RADIUS, 'avoid_players': MIN_DIST_BETWEEN_PLAYERS }
	var player_data = GlobalDict.player_data
	
	for i in range(max_players):
		if not player_data[i].active: continue
		
		var p = player_scene.instance()
		map.entities.add_child(p)
		
		p.set_position(spawner.get_valid_pos(params))
		
		p.modules.shaper.create_from_shape(shape_manager.select_random_pumpkin_shape())
		p.modules.status.set_player_num(i)
		p.modules.status.set_team_num(player_data[i].team)
		
		if player_data[i].bot:
			p.modules.status.turn_into_bot()

func get_players_in_team(team_num):
	var players = get_tree().get_nodes_in_group("Players")
	var arr = []
	for p in players:
		if p.modules.status.team_num != team_num: continue
		arr.append(p)
	return arr
