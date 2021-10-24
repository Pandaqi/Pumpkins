extends Node

var player_num : int = -1
var team_num : int = -1
var is_dead : bool = false
var is_bot : bool = false

var is_ghost : bool = false

onready var body = get_parent()
onready var particles = get_node("/root/Main/Particles")
onready var mode = get_node("/root/Main/ModeManager")

var powerup_part_color : Color = Color(0.0, 204.0/255.0, 72.0/255.0)
var dumpling_part_color : Color = Color(1.0, 207/255.0, 112/255.0)

func set_player_num(num):
	player_num = num
	
	body.modules.drawer.set_color(GlobalDict.player_colors[num])
	if body.modules.has('fader'):
		body.modules.fader.activate(is_from_a_player())
	
	set_player_specific_data()

func set_player_specific_data():
	if not body.is_in_group("Players"): return
	
	if body.modules.has('input'):
		body.modules.input.set_player_num(player_num)
	
	if body.modules.has('bot'):
		body.modules.bot.set_player_num(player_num)
	
	body.modules.slasher.set_player_num(player_num)
	body.modules.knives.activate()
	body.modules.topping.set_frame(player_num)
	
	if body.modules.has('tutorial'):
		body.modules.tutorial.activate(player_num)

func is_from_a_player():
	return player_num >= 0

func is_from_specific_player(num):
	return (player_num == num)

func set_team_num(num):
	team_num = num
	
	body.modules.particles.update_team_num(team_num)

func turn_into_bot():
	is_bot = true
	
	var input = get_node("../Input")
	input.get_parent().remove_child(input)
	input.queue_free()
	
	var tutorial = get_node("../Tutorial")
	tutorial.get_parent().remove_child(tutorial)
	tutorial.self_destruct()

func turn_into_player():
	var bot = get_node("../Bot")
	bot.get_parent().remove_child(bot)
	bot.queue_free()
	
	if (not GlobalDict.cfg.tutorial) or Global.is_restart: 
		var tutorial = get_node("../Tutorial")
		tutorial.get_parent().remove_child(tutorial)
		tutorial.self_destruct()

func rotate_incrementally():
	if is_bot: return false
	return GlobalInput.is_keyboard_player(player_num)

func make_powerup_leftover():
	player_num = -1
	body.modules.drawer.set_color(powerup_part_color)

func make_dumpling_leftover():
	player_num = -1
	body.modules.drawer.set_color(dumpling_part_color)

func delete():
	body.queue_free()

func can_die():
	return mode.players_can_die()

func die():
	is_dead = true
	make_ghost()
	
	body.modules.knives.destroy_knives()
	body.modules.collector.disable_collection()
	body.modules.powerups.disable()
	
	particles.create_explosion_particles(body.global_position)
	GlobalAudio.play_dynamic_sound(body, "death")

func make_ghost():
	body.modulate.a = 0.6
	
	is_ghost = true
	
	body.collision_layer = 16 # (layer 5; 2^4)
	body.collision_mask = 16
	
	body.modules.topping.make_ghost()
	body.modules.drawer.disable()

func undo_ghost():
	if is_dead: return
	
	body.modulate.a = 1.0
	
	is_ghost = false
	
	body.collision_layer = 1 + 2
	body.collision_mask = 0
	
	body.modules.topping.set_frame(player_num)
	body.modules.drawer.enable()
