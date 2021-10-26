extends Node2D

onready var players = $Players
onready var powerups = $Powerups
onready var throwables = $Throwables
onready var game_state = $GameState
onready var shape_manager = $ShapeManager
onready var arena = $ArenaLoader
onready var mode = $ModeManager
onready var navigation = $Navigation
onready var start_delay = $StartDelay
onready var map = $Map

var game_officially_started : bool = false

func _ready():
	randomize()
	
	if GlobalInput.get_player_count() <= 0:
		GlobalInput.create_debugging_players()
	
	shape_manager.activate()
	mode.activate()
	arena.activate()
	navigation.activate()
	players.activate()
	throwables.activate()
	powerups.activate()
	game_state.activate()
	
	start_delay.activate()
	
	if not GlobalDict.cfg.light_effects:
		remove_all_light_effects()
	
	#debug_game_over()

func remove_all_light_effects():
	recursively_remove_lights_from(map)
	recursively_remove_lights_from(arena.custom_logic)

func recursively_remove_lights_from(node):
	for N in node.get_children():
		if N is Light2D or N is LightOccluder2D or N is CanvasModulate: 
			if not N.is_in_group("KeepLights"):
				N.queue_free()
				continue
		
		if N.get_child_count() > 0:
			recursively_remove_lights_from(N)

func start_game():
	game_officially_started = true

func debug_game_over():
	var winner = get_tree().get_nodes_in_group("Players")[0].modules.status.team_num
	game_state.game_over(winner)

func player_died(num):
	game_state.player_died(num)

func player_progression(num):
	game_state.player_progression(num)
