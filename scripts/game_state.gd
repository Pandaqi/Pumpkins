extends Node

var game_over_state : bool = false
var interface_available : bool = false

onready var player_manager = get_node("../Players")
onready var mode = get_node("../ModeManager")

func activate():
	pass

func player_died(num):
	print("PLAYER DIED: " + str(num))
	
	check_win_condition()

func player_progression(num):
	print("PLAYER PROGRESSED: " + str(num))
	check_win_condition()

func check_win_condition():
	if game_over_state: return

	if mode.win_type_is("survival"):
		check_win_by_survival()
	elif mode.win_type_is("collection"):
		check_win_by_collection()

func check_win_by_survival():
	var players = get_tree().get_nodes_in_group("Players")
	
	var players_alive = 0
	var last_player_alive = null
	var teams_left = []
	
	for p in players:
		if p.modules.status.is_dead: continue
		
		players_alive += 1
		last_player_alive = p
		
		teams_left.append(p.modules.status.team_num)
	
	var only_one_team_remains = true
	for i in range(1, teams_left.size()):
		if teams_left[i] == teams_left[i-1]: continue
		only_one_team_remains = false
		break
	
	if players_alive <= 1 or only_one_team_remains:
		game_over(int(teams_left[0]))

func check_win_by_collection():
	var players = get_tree().get_nodes_in_group("Players")
	var count_per_team = {}
	var required_count_per_team = {}

	for p in players:
		var team_num = p.modules.status.team_num
		
		if not count_per_team.has(team_num):
			count_per_team[team_num] = 0
			required_count_per_team[team_num] = 0
		
		count_per_team[team_num] += p.modules.collector.count()
		required_count_per_team[team_num] += mode.get_target_number()
	
	for team_num in count_per_team:
		var val = count_per_team[team_num]
		if val < required_count_per_team[team_num]: continue
		
		game_over(int(team_num))
		break

func game_over(team_num):
	var team = player_manager.get_players_in_team(team_num)
	
	print("GAME OVER")
	print("Winning team: " + str(team))
	
	game_over_state = true
	
	var players = get_tree().get_nodes_in_group("Players")
	var instructions_handed_out = false
	for p in players:
		var is_winner = (p in team)
		p.modules.gameover.enable(is_winner)
		
		if is_winner and not instructions_handed_out: 
			p.modules.gameover.add_instructions()
			instructions_handed_out = true
		else:
			p.modules.gameover.remove_instructions()

func _input(ev):
	if not game_over_state: return
	if not interface_available: return
	
	if ev.is_action_released("restart"):
		Global.restart()
	
	elif ev.is_action_released("exit"):
		Global.load_menu()
