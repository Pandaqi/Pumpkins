extends Node

var num_succesful_actions : int = 0
var being_held : bool = false
var is_stuck : bool = false

var type : String = "knife"
var base_frame : int = 0

var in_water : bool = false

var is_forbidden : bool = false
var forbidden_node = null

onready var body = get_parent()
onready var sprite = get_node("../Sprite")
onready var throwables = get_node("/root/Main/Throwables")

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
		
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 8
		body.modules.collisionshape2d.shape = circle_shape
		
		body.modules.shadowlocation.type = "circle"
		body.modules.shadowlocation.extents.x = 24

func record_succesful_actions():
	if num_succesful_actions <= 0: return
	if body.modules.owner.has_none(): return
	
	var player = body.modules.owner.get_owner()
	player.modules.statistics.record("knives_succesful", 1)

func record_succesful_action(val):
	num_succesful_actions += val

func reset_to_held_and_stuck_state():
	reset_to_held_state()
	
	is_stuck = true

func reset_to_forbidden_held_state():
	reset_to_held_state()
	
	is_forbidden = true

func reset_to_held_state():
	is_stuck = false
	being_held = true
	in_water = false
	body.show_behind_parent = true
	sprite.set_rotation(0.5*PI)
	record_succesful_actions()

func reset_to_thrown_state():
	num_succesful_actions = 0
	is_stuck = false
	being_held = false
	is_forbidden = false
	body.show_behind_parent = false

func reset_to_stuck_state():
	is_stuck = true
	being_held = false
	record_succesful_actions()

func enter_water():
	in_water = true

func exit_water():
	in_water = false

func react_to_areas():
	return not being_held

func delete():
	throwables.change_count(-1)
	body.queue_free()
