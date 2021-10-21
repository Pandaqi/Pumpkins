extends Node2D

onready var container = $Container
onready var settings = $Settings

onready var tween = $Tween

var player_add_scene = preload("res://scenes/gui/player_add.tscn")
var max_players = GlobalDict.base_cfg.max_players
var interfaces = []

var num_bots = 0

func _ready():
	fill_container()

func save_configuration():
	for i in range(max_players):
		var interface = interfaces[i]
		GlobalDict.player_data[i] = interface.get_data()

func count_total_players():
	var sum = 0
	for i in range(max_players):
		if not GlobalDict.player_data[i].active: break
		sum += 1
	return sum

func change_team(player_num : int):
	var interface = interfaces[player_num]
	
	interface.change_team()
	play_team_changed_tween(interface)

func fill_container():
	var num_cols = 3
	var num_rows = ceil(max_players / float(num_cols))
	
	var add_size = 420
	var offset = -Vector2(0.5*(num_cols-1), 0.5*(num_rows-1))*add_size

	for i in range(max_players):
		var col = i % num_cols
		var row = floor(i / num_cols)
		
		var pos = Vector2(col, row)*add_size + offset
		
		var p = player_add_scene.instance()
		p.set_position(pos)
		container.add_child(p)
		
		p.set_player_num(i)
		play_appearance_tween(p)
		interfaces.append(p)
	
	update_interface(false)
	play_appearance_tween(settings)

func play_changed_tween(p):
	
	tween.interpolate_property(p, "scale", 
		Vector2(1,1)*1.3, Vector2(1,1), 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(p, "rotation", 
		0, 2*PI, 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		
	tween.start()

func play_appearance_tween(p):
	var duration = 1.0
	
	p.set_scale(Vector2.ZERO)
	tween.interpolate_property(p, "scale", 
		Vector2.ZERO, Vector2(1,1), 2*duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(p, "rotation", 
		0, 2*PI, duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.start()

func play_team_changed_tween(interface):
	var duration = 0.3
	var p = interface.get_node("Team")
	
	p.set_scale(Vector2.ZERO)
	tween.interpolate_property(p, "scale", 
		Vector2(1,1)*1.3, Vector2(1,1), duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.interpolate_property(p, "rotation", 
		0, 2*PI, duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	
	tween.start()

func update_interface(play_tweens : bool = true):
	var cur_num_players = GlobalInput.get_player_count()
	var total_num_with_bots = (cur_num_players+num_bots)
	
	var last_keyboard_player = null
	var last_bot_player = null
	for i in range(max_players):
		var interface = interfaces[i]
		var old_state = interface.state
		
		if i >= total_num_with_bots:
			interface.disable()
		else:
			interface.enable()
			
			if i < cur_num_players:
				interface.make_human()
				if GlobalInput.is_keyboard_player(i):
					interface.show_extra_buttons('keyboard')
					last_keyboard_player = interface
				else:
					interface.show_extra_buttons('controller')
			else:
				interface.make_bot()
				last_bot_player = interface
		
		if i == total_num_with_bots:
			interface.open()
		
		var new_state = interface.state
		if new_state != old_state and play_tweens:
			play_changed_tween(interface)
	
	if last_keyboard_player:
		last_keyboard_player.show_keyboard_leave_button()
	
	if last_bot_player:
		last_bot_player.show_bot_leave_button()

func add_bot():
	num_bots += 1
	update_interface()

func remove_bot():
	num_bots -= 1
	update_interface()

func player_removed(num):
	# all interfaces AFTER this one should move one forward
	# in other words, they copy the data from the interface AFTER them
	for i in range(num, max_players-1):
		interfaces[i].set_data(interfaces[i+1].get_data())
	
	update_interface()
	
	
	
