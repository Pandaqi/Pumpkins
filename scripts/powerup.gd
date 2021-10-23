extends StaticBody2D

const POWERUP_SCALE : float = 0.66

var type : String
var modules = {}

onready var map = get_node("/root/Main/Map")
onready var shape_manager = get_node("/root/Main/ShapeManager")
onready var slicer = get_node("/root/Main/Slicer")

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

func auto_slice():
	var rot = 2*PI*randf()
	var vec = Vector2(cos(rot), sin(rot))
	var bottom_left = get_global_position() - vec*100
	var top_right = get_global_position() + vec*100
	slicer.slice_bodies_hitting_line(bottom_left, top_right, [], [self])

func reveal_powerup(attacker):
	if attacker:
		attacker.modules.statistics.record("powerups_opened", 1)
	
	var original_pos = revealed_powerup.get_global_position()
	
	self.call_deferred("remove_child", revealed_powerup)
	map.knives.call_deferred("add_child", revealed_powerup)
	
	revealed_powerup.call_deferred("reveal", original_pos)
	
	self.queue_free()
