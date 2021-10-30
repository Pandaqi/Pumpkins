extends Node2D

export var wait_time : float = 15.0

onready var timer = $Timer
onready var body = get_parent()

onready var map = get_node("/root/Main/Map")

func _ready():
	timer.wait_time = wait_time
	timer.start()

func _on_Timer_timeout():
	throw_away_all_throwables_we_own()
	
	body.queue_free()

func throw_away_all_throwables_we_own():
	for child in get_children():
		if child.is_in_group("Throwables"):
			var vec = (child.global_position - global_position).normalized() * 1000.0
			
			remove_child(child)
			map.knives.add_child(child)
			
			child.throw(null, vec)
