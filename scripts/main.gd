extends Node2D

onready var players = $Players

func _ready():
	if GlobalInput.get_player_count() <= 0:
		GlobalInput.create_debugging_players()
	
	players.activate()

func player_died(num):
	print("PLAYER DIED: " + str(num))
	pass
