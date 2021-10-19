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
	
	body.modules.knives.create_starting_knives()
	body.modules.topping.set_frame(player_num)

func set_team_num(num):
	team_num = num

func turn_into_bot():
	body.modules.input.queue_free()
	body.modules.erase("input")

func turn_into_player():
	body.modules.bot.queue_free()
	body.modules.erase("bot")

func make_powerup_leftover():
	body.modules.drawer.set_color(powerup_part_color)

func delete():
	body.queue_free()

func die():
	is_dead = true
	make_ghost()
	
	body.modules.knives.destroy_knives()

func make_ghost():
	body.modulate.a = 0.6
	
	is_ghost = true
	
	body.collision_layer = 0
	body.collision_mask = 0
	
	body.modules.topping.set_frame(player_num + 6)

func undo_ghost():
	body.modulate.a = 1.0
	
	is_ghost = false
	
	body.collision_layer = 1 + 2
	body.collision_mask = 1 + 2
	
	body.modules.topping.set_frame(player_num)
