extends Node2D

var is_day : bool = true
var lights = []

var night_color : Color = Color(10/255.0, 60/255.0, 10/255.0)
var ghost_knives = []

var cave_positions = [Vector2(150,50), Vector2(1750, 1025)]

onready var canvas_mod = $CanvasModulate
onready var throwables = get_node("/root/Main/Throwables")
onready var timer = $Timer
onready var tween = $Tween

var dead_players = []

func activate():
	for child in get_children():
		if child is Light2D:
			lights.append(child)
	
	is_day = false
	change_mode()
	
	timer.start()

func on_player_death(p) -> Dictionary:
	dead_players.append(p)
	
	p.modules.status.hide_completely()
	
	return { }

func change_mode():
	is_day = not is_day
	
	# lights only appear during the day
	var delay = 0.0
	var delay_step = 0.2
	for light in lights:
		tween.interpolate_property(light, "visible",
			is_day, not is_day, 1.0,
			Tween.TRANS_LINEAR, Tween.EASE_OUT,
			delay)
		
		delay += delay_step
	
	# don't need to modulate if no lights active
	var color = night_color
	if is_day: color = Color(1,1,1)
	
	tween.interpolate_property(canvas_mod, "color",
		canvas_mod.color, color, 1.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	# at night, do something special
	if not is_day:
		make_someone_a_ghost()
		make_ghost_knives_appear()
	else:
		unmake_all_ghosts()
	
	tween.start()

func make_someone_a_ghost():
	var players = get_tree().get_nodes_in_group("Players")
	players.shuffle()
	players[0].modules.status.make_ghost()

func unmake_all_ghosts():
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		p.modules.status.undo_ghost()

func make_ghost_knives_appear():
	ghost_knives = []
	
	# make them appear
	for pos in cave_positions:
		var gk = throwables.create("ghost_knife")
		gk.set_position(pos)
		ghost_knives.append(gk)
	
	# now assign dead players (alternating) to control them
	var counter : int = 0
	for p in dead_players:
		var index = (counter % 2)
		var target_module = ghost_knives[index].modules.mover
		
		p.modules.input.connect("move_vec", target_module, "add_to_override_vec")
		
		counter += 1

func _on_Timer_timeout():
	change_mode()
