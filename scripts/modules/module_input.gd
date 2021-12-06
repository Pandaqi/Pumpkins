extends Node

var player_num : int = -1

onready var body = get_parent()

signal move_vec(vec, dt)

signal button_press()
signal button_release()

func get_key(key : String):
	var device_num = GlobalInput.device_order[player_num]
	return key + "_" + str(device_num)

func set_player_num(num : int):
	player_num = num

func _physics_process(dt):
	if player_num >= GlobalInput.get_player_count(): return
	determine_move_vec(dt)

func determine_move_vec(dt):
	var h = Input.get_action_strength(get_key("right")) - Input.get_action_strength(get_key("left"))
	var v = Input.get_action_strength(get_key("down")) - Input.get_action_strength(get_key("up"))
	var move_vec = Vector2(h,v).normalized()
	
	if body.modules.specialstatus.stun.is_stunned: 
		move_vec = Vector2.ZERO
	
	emit_signal("move_vec", move_vec, dt)

func _input(ev):
	if not ((ev is InputEventKey) or (ev is InputEventJoypadButton)): return
	if player_num >= GlobalInput.get_player_count(): return
	if GlobalDict.cfg.auto_throw_knives: return

	if ev.is_action_pressed(get_key("interact")):
		emit_signal("button_press")
	elif ev.is_action_released(get_key("interact")):
		emit_signal("button_release")
