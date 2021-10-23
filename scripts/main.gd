extends Node2D

onready var players = $Players
onready var powerups = $Powerups
onready var game_state = $GameState
onready var shape_manager = $ShapeManager
onready var arena = $ArenaLoader
onready var mode = $ModeManager
onready var navigation = $Navigation
onready var start_delay = $StartDelay

func _ready():
	randomize()
	
	if GlobalInput.get_player_count() <= 0:
		GlobalInput.create_debugging_players()
	
	shape_manager.activate()
	mode.activate()
	arena.activate()
	navigation.activate()
	players.activate()
	powerups.activate()
	game_state.activate()
	
	start_delay.activate()
	
	#debug_game_over()

func debug_game_over():
	var winner = get_tree().get_nodes_in_group("Players")[0].modules.status.team_num
	game_state.game_over(winner)

func player_died(num):
	game_state.player_died(num)

func player_progression(num):
	game_state.player_progression(num)
