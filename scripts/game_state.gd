extends Node

var game_over_state : bool = false
var interface_available : bool = false

onready var player_manager = get_node("../Players")
onready var mode = get_node("../ModeManager")
onready var start_delay = get_node("../StartDelay")
onready var particles = get_node("../Particles")

var awards = {
	"players_sliced": "Players Sliced",
	"knives_used": "Knives Used",
	"succesful_attacks": "Succesful Attacks (%)",
	"powerups_opened": "Powerups Opened",
	"throwables_opened": "Throwables Opened",
	"powerups_grabbed": "Powerups Grabbed",
	"throwables_grabbed": "Throwables Grabbed",
	"distance_traveled": "Distance Traveled (km)",
	"average_size": "Average Size (m)",
	"quick_stabs": "Quick Stabs",
	"long_throws": "Long Throws"
}

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
	var teams_left = []
	
	for p in players:
		if p.modules.status.is_dead: continue
		players_alive += 1
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
	var players_per_team = {}

	for p in players:
		var team_num = p.modules.status.team_num
		
		if not count_per_team.has(team_num):
			count_per_team[team_num] = 0
			required_count_per_team[team_num] = 0
			players_per_team[team_num] = []
		
		count_per_team[team_num] += p.modules.collector.count()
		required_count_per_team[team_num] += mode.get_target_number()
		players_per_team[team_num].append(p)
	
	for team_num in count_per_team:
		var val = count_per_team[team_num]
		var target = required_count_per_team[team_num]
		inform_players_of_almost_winning(val, target, players_per_team[team_num])
		
		if val < target: continue
		
		game_over(int(team_num))
		break

func inform_players_of_almost_winning(val, target, players_in_team):
	var margin = 2
	if val < (target - margin): return
	if val >= target: return
	
	for p in players_in_team:
		particles.general_feedback(p.global_position, "Almost won!")

func game_over(team_num):
	game_over_state = true
	
	GlobalAudio.play_static_sound("game_over")
	
	handout_awards()
	show_gameover_gui(team_num)
	start_delay.game_over(team_num)
	
	if has_node("../AreaShrink"): get_node("../AreaShrink").game_over()

func handout_awards():
	# Step 1: create list of each statistic (val, player) and sort them
	var players = get_tree().get_nodes_in_group("Players")
	var final_results = {}
	
	for stat in awards:
		final_results[stat] = []
		
		for p in players:
			# some things can only be calculated once the game is completely done; do so now
			p.modules.statistics.finalize_awards()
			
			var obj = { 
				'val': p.modules.statistics.read(stat), 
				'num': p.modules.status.player_num 
			}
			
			final_results[stat].append(obj)
		
		final_results[stat].sort_custom(self, "award_sort")
	
	# Step 2: for each player, find lists where they are either FIRST or LAST
	for p in players:
		var wins = []
		var num = p.modules.status.player_num
		
		for stat in final_results:
			var list = final_results[stat]
			if list[0].num == num:
				var obj = { 
					'stat': stat, 
					'type': 'high', 
					'val': list[0].val 
				}
				
				wins.append(obj)
			elif list[list.size() - 1].num == num:
				var obj = { 
					'stat': stat, 
					'type': 'low', 
					'val': list[list.size() - 1].val
				}
				wins.append(obj)
		
		var no_award_possible = (wins.size() <= 0)
		if no_award_possible:
			wins = [{ 'stat': 'passive', 'type': 'high', 'val': INF }]
			continue
	
		# Step 3: pick a random one and assign it to the my_award variable on the player
		var random_choice = wins[randi() % wins.size()]
		
		var award_val = random_choice.val
		var award_name = awards[random_choice.stat]
		var type = random_choice.type # low or high
		
		p.modules.statistics.set_award(award_name, award_val, type)

func show_gameover_gui(team_num):
	var team = player_manager.get_players_in_team(team_num)

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
		
		if p.modules.status.is_dead:
			p.modules.status.show_again()

func _input(ev):
	if not game_over_state: return
	if not interface_available: return
	
	if ev.is_action_released("restart"):
		GlobalAudio.play_static_sound("ui_button_press")
		Global.restart()
	
	elif ev.is_action_released("exit"):
		GlobalAudio.play_static_sound("ui_button_press")
		Global.load_menu()
