extends Node2D

onready var players = $Players
onready var powerups = $Powerups
onready var game_state = $GameState
onready var shape_manager = $ShapeManager

func _ready():
	if GlobalInput.get_player_count() <= 0:
		GlobalInput.create_debugging_players()
	
	shape_manager.activate()
	players.activate()
	powerups.activate()
	game_state.activate()

func player_died(num):
	game_state.player_died(num)

func player_progression(num):
	game_state.player_progression(num)
