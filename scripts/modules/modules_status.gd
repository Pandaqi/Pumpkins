extends Node

var player_num : int = -1
var team_num : int = -1
var is_dead : bool = false

var is_ghost : bool = false

onready var body = get_parent()

var powerup_part_color : Color = Color(0.0, 204.0/255.0, 72.0/255.0)

func set_player_num(num):
	player_num = num
	
	body.modules.drawer.set_color(GlobalDict.player_colors[num])
	
	if not body.is_in_group("Players"): return
	
	body.modules.input.set_player_num(num)
	body.modules.bot.set_player_num(num)
	
	body.modules.knives.activate()
	body.modules.topping.set_frame(player_num)

func is_from_a_player():
	return player_num >= 0

func is_from_specific_player(num):
	return (player_num == num)

func set_team_num(num):
	team_num = num
	
	body.modules.particles.update_team_num(team_num)

func turn_into_bot():
	get_parent().get_node("Input").queue_free()

func turn_into_player():
	get_parent().get_node("Bot").queue_free()

func make_powerup_leftover():
	player_num = -1
	body.modules.drawer.set_color(powerup_part_color)

func delete():
	body.queue_free()

func die():
	is_dead = true
	make_ghost()
	
	body.modules.knives.destroy_knives()
	body.modules.collector.disable_collection()
	body.modules.powerups.disable()

func make_ghost():
	body.modulate.a = 0.6
	
	is_ghost = true
	
	body.collision_layer = 16 # (layer 5; 2^4)
	body.collision_mask = 16
	
	body.modules.topping.make_ghost()

func undo_ghost():
	body.modulate.a = 1.0
	
	is_ghost = false
	
	body.collision_layer = 1 + 2
	body.collision_mask = 0
	
	body.modules.topping.set_frame(player_num)
