extends StaticBody2D

var type : String
var modules = {}

onready var main_node = get_node("/root/Main")

onready var revealed_powerup = $RevealedPowerup

func _ready():
	revealed_powerup.unreveal()

func set_type(tp):
	revealed_powerup.set_type(tp)
	revealed_powerup.hide()

func get_type():
	return revealed_powerup.type

func reveal_powerup():
	var original_pos = revealed_powerup.get_global_position()
	
	self.call_deferred("remove_child", revealed_powerup)
	main_node.call_deferred("add_child", revealed_powerup)
	
	revealed_powerup.call_deferred("reveal", original_pos)
	
	self.queue_free()
