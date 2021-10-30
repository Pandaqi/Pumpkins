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
	body.modules.status.delete()

func throw_away_all_throwables_we_own():
	for child in body.get_children():
		if child.is_in_group("Throwables"):
			var old_pos = child.global_position
			var old_rot = child.global_rotation
			var vec = (old_pos - global_position).normalized() * 1000.0
			
			child.get_parent().remove_child(child)
			map.knives.add_child(child)
			
			child.set_position(old_pos)
			child.set_rotation(old_rot)
			
			child.modules.thrower.throw(null, vec)
