extends Node

const KNIFE_SHOOT_VEL : float = 1000.0

onready var wall = get_parent()
onready var throwables = get_node("/root/Main/Throwables")
onready var timer = $Timer

func activate():
	_on_Timer_timeout()

func deactivate():
	timer.stop()

func _on_Timer_timeout():
	timer.start()
	shoot_knife()

func get_random_player():
	var players = get_tree().get_nodes_in_group("Players")
	players.shuffle()
	return players[0]

func shoot_knife():
	var k = throwables.create('knife')
	
	var margin = 20
	var rand_pos = Vector2(0, randf()*(1080-2*margin) + margin)
	k.set_position(rand_pos)
	
	k.set_velocity(Vector2.RIGHT * KNIFE_SHOOT_VEL)
	k.modules.owner.set_owner(get_random_player())
	
	wall.bodies_created.append(k)
	
	# TO DO: similarly, create "hostile" knives in any case
	# TO DO: with some (high) probability, just create a ghost knife? Or some other throwable?
