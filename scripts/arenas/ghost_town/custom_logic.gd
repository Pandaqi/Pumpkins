extends Node2D

var is_day : bool = true
var lights = []

var night_color : Color = Color(10/255.0, 60/255.0, 10/255.0)
var ghost_knife = null

onready var canvas_mod = $CanvasModulate
onready var timer = $Timer

func activate():
	for child in get_children():
		if child is Light2D:
			lights.append(child)
	
	is_day = false
	change_mode()
	
	timer.start()

# TO DO: Make this change more gradual (also for performance reasons)
# (Add lights one by one, fade canvas modulate)
func change_mode():
	is_day = not is_day
	
	# lights only appear during the day
	for light in lights:
		light.set_visible(not is_day)
	
	# don't need to modulate if no lights active
	var color = night_color
	if is_day: color = Color(1,1,1)
	canvas_mod.color = color
	
	# at night, do something special
	if not is_day:
		if randf() <= 0.5:
			make_all_players_ghosts()
		else:
			make_ghost_knife_appear()
	else:
		unmake_all_ghosts()
		remove_ghost_knife()

func make_all_players_ghosts():
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		p.modules.status.make_ghost()

func unmake_all_ghosts():
	var players = get_tree().get_nodes_in_group("Players")
	for p in players:
		p.modules.status.undo_ghost()

func make_ghost_knife_appear():
	# TO DO:
	# Spawn bodyless projectile
	# Call function on it (turn_into_ghost_projectile)
	#  => Makes it ownerless
	#  => Makes its velocity low but constant
	#  => Chases players nearby
	#  => Never allow grabbing; disappears when day starts
	#
	# ACTUALLY MAKE THIS A THROWABLE TYPE?
	pass

func remove_ghost_knife():
	if not ghost_knife: return
	
	ghost_knife.queue_free()
	ghost_knife = null

func _on_Timer_timeout():
	change_mode()
