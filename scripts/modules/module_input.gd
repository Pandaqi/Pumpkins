extends Node

var player_num : int = -1

signal move_vec()

signal button_press()
signal button_release()

func get_key(key : String):
	var device_num = GlobalInput.device_order[player_num]
	return key + "_" + str(device_num)

func set_player_num(num : int):
	player_num = num

func _physics_process(_dt):
	determine_move_vec()

func determine_move_vec():
	var h = Input.get_action_strength(get_key("right")) - Input.get_action_strength(get_key("left"))
	var v = Input.get_action_strength(get_key("down")) - Input.get_action_strength(get_key("up"))
	var move_vec = Vector2(h,v).normalized()
	
	emit_signal("move_vec", move_vec)

func _input(ev):
	if ev.is_action_pressed(get_key("interact")):
		emit_signal("button_press")
	elif ev.is_action_released(get_key("interact")):
		emit_signal("button_release")
