extends Node

var num_succesful_actions : int = 0
var being_held : bool = false
var is_stuck : bool = false

var type : String = "knife"
var base_frame : int = 0

onready var body = get_parent()
onready var sprite = get_node("../Sprite")

func set_type(tp):
	type = tp
	
	var data = GlobalDict.throwables[type]

	base_frame = data.base_frame
	sprite.set_frame(base_frame)
	
	body.modules.owner.set_mode(data.owner)
	body.modules.mover.set_body(data.body)
	body.modules.fakebody.set_body(data.body)
	
	if type == "boomerang":
		body.modules.shadowlocation.type = "circle"
	
	if data.category == "dumpling":
		body.add_to_group("Dumplings")

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
