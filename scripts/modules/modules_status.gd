extends Node

var player_num : int = -1

onready var body = get_parent()

func set_player_num(num):
	player_num = num
	
	var is_player = body.modules.has('input')
	if not is_player: return
	
	body.modules.input.set_player_num(num)
	body.modules.drawer.set_color(GlobalDict.player_colors[num])
	body.modules.knives.create_starting_knives()

func delete():
	body.queue_free()
