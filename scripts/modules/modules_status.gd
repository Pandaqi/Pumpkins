extends Node

var player_num : int = -1
var is_dead : bool = false

var is_ghost : bool = false

onready var body = get_parent()

func set_player_num(num):
	player_num = num
	
	var is_player = body.modules.has('input')
	if not is_player: return
	
	body.modules.input.set_player_num(num)
	body.modules.drawer.set_color(GlobalDict.player_colors[num])
	body.modules.knives.create_starting_knives()
	body.modules.topping.set_frame(player_num)

func delete():
	body.queue_free()

func die():
	is_dead = true
	
	body.modules.knives.destroy_knives()

func make_ghost():
	body.modulate.a = 0.6
	
	is_ghost = true
	
	body.collision_layer = 0
	body.collision_mask = 0

func undo_ghost():
	body.modulate.a = 1.0
	
	is_ghost = false
	
	body.collision_layer = 1 + 2
	body.collision_mask = 1 + 2
