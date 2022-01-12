extends Node2D

var TIMER_BOUNDS = { 'min': 5, 'max': 15 }
var curtains = []
var cur_curtain_opened = null

onready var timer = $Timer

func activate():
	curtains = get_tree().get_nodes_in_group("Curtains")
	for c in curtains:
		c.close()
	
	_on_Timer_timeout()

func on_player_death(_p) -> Dictionary:
	return {}

func open_different_curtain():
	if cur_curtain_opened:
		cur_curtain_opened.close()
	
	var index = curtains.find(cur_curtain_opened)
	var offset = randi() % int(curtains.size() - 1)
	var new_index = (index + offset) % int(curtains.size())
	
	cur_curtain_opened = curtains[new_index]
	cur_curtain_opened.open()

func _on_Timer_timeout():
	timer.wait_time = rand_range(TIMER_BOUNDS.min, TIMER_BOUNDS.max)
	timer.start()
	open_different_curtain()
