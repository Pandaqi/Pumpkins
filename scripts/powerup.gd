extends StaticBody2D

const POWERUP_SCALE : float = 0.66

var type : String
var modules = {}

onready var main_node = get_node("/root/Main")
onready var shape_manager = get_node("/root/Main/ShapeManager")

onready var sprite = $Sprite
onready var revealed_powerup = $RevealedPowerup

onready var col_shape = $CollisionShape2D

func _ready():
	revealed_powerup.unreveal()

func set_shape(shape_name):
	var data = GlobalDict.predefined_shapes[shape_name]
	var points = shape_manager.scale_shape(data.points, POWERUP_SCALE)
	var frame = data.frame
	
	sprite.set_frame(frame)
	
	col_shape.polygon = points

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
