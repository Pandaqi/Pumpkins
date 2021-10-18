extends Node

# Game modes = [deathmatch, collector, bullseye, dumplings]
var game_mode : String = "deathmatch"
var min_collections_needed_to_win : int = 5

var game_over_state : bool = false

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
	
	#call("check_win_" + game_mode) => would be fine, but most modes actually do similar things
	
	if game_mode == "deathmatch":
		check_win_deathmatch()
	else:
		check_win_by_collection()

func check_win_deathmatch():
	var players = get_tree().get_nodes_in_group("Players")
	var players_alive = 0
	var last_player_alive = null
	
	for p in players:
		if p.modules.status.is_dead: continue
		players_alive += 1
		last_player_alive = p
	
	if players_alive <= 1:
		game_over(last_player_alive)

func check_win_by_collection():
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		if p.modules.collector.count() < min_collections_needed_to_win: continue
		
		game_over(p)
		break

func game_over(winner):
	print("GAME OVER")
	print(winner)
	
	game_over_state = true
	
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		var is_winner = (p == winner)
		p.modules.gameover.enable(is_winner)
		
		if is_winner: 
			p.modules.gameover.add_instructions()

func _input(ev):
	if not game_over_state: return
	
	if ev.is_action_released("restart"):
		get_tree().reload_current_scene()
	
	elif ev.is_action_released("exit"):
		pass
