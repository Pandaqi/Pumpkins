extends Node

var collector_scene = preload("res://scenes/gui/collector.tscn")

onready var map = get_node("../Map")
onready var players = get_node("../Players")

var collectors = {}

func place(obj):
	var counter = 0
	for child in obj.get_children():
		if not GlobalDict.player_data[counter].active: return
		
		var team = GlobalDict.player_data[counter].team
		place_collector(child, team)
		counter += 1

func place_collector(child, team_num : int):
	var already_placed_collector_for_team = collectors.has(team_num)
	if already_placed_collector_for_team: return
	
	var c = collector_scene.instance()
	c.set_position(child.get_position())
	
	map.overlay.add_child(c)
	collectors[team_num] = c
	
	c.update_team(team_num)
	c.update_label(0)

func show_player_icons():
	for key in collectors:
		collectors[key].update_players_in_team(players.get_players_in_team(int(key)))

func update_team_count(team_num):
	var players_in_team = players.get_players_in_team(team_num)
	var sum = 0
	for p in players_in_team:
		sum += p.modules.collector.count()
	
	collectors[team_num].update_label(sum)
