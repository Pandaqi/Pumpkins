extends Node

const KNIFE_SHOOT_VEL : float = 1000.0
const GHOST_KNIFE_PROBABILITY : float = 0.05
const HOSTILE_KNIFE_PROBABILITY : float = 0.1

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
	if players.size() <= 0: return null
	
	players.shuffle()
	return players[0]

func shoot_knife():
	var type = 'knife'
	if randf() <= GHOST_KNIFE_PROBABILITY:
		type = 'ghost_knife'
	
	var k = throwables.create(type)
	
	var margin = 20
	var rand_pos = Vector2(0, randf()*(1080-2*margin) + margin)
	k.set_position(rand_pos)
	
	k.modules.mover.set_velocity(Vector2.RIGHT * KNIFE_SHOOT_VEL)
	k.modules.mover.make_constant()
	
	wall.register_body(k)
	
	var owner = get_random_player()
	if not owner: return
	
	k.modules.owner.set_owner(owner)
	
	if randf() <= HOSTILE_KNIFE_PROBABILITY:
		k.modules.owner.remove()
		k.modules.owner.set_mode("hostile")
