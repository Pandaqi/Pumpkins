extends Node2D

onready var players = $Players
onready var powerups = $Powerups
onready var game_state = $GameState

func _ready():
	if GlobalInput.get_player_count() <= 0:
		GlobalInput.create_debugging_players()
	
	players.activate()
	powerups.activate()
	game_state.activate()

func player_died(num):
	game_state.player_died(num)
