extends Node

var num_succesful_actions : int = 0
var being_held : bool = false
var is_stuck : bool = false

var type : String = "knife"

onready var body = get_parent()
onready var sprite = get_node("../Sprite")

func record_succesful_actions():
	if num_succesful_actions <= 0: return
	if body.modules.owner.has_none(): return
	
	var player = body.modules.owner.get_owner()
	player.modules.statistics.record("knives_succesful", 1)

func record_succesful_action(val):
	num_succesful_actions += val

func reset_to_held_state():
	is_stuck = false
	being_held = true
	sprite.set_rotation(0.5*PI)
	record_succesful_actions()

func reset_to_thrown_state():
	num_succesful_actions = 0
	is_stuck = false
	being_held = false

func reset_to_stuck_state():
	is_stuck = true
	being_held = false
	record_succesful_actions()
