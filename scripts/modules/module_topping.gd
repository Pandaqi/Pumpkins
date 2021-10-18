extends Node2D

onready var body = get_parent()

var original_size : float = 256.0

func set_frame(num):
	$Sprite.set_frame(num)

func _on_Shaper_shape_updated():
	var radius = 2*body.modules.shaper.approximate_radius()
	var new_scale = radius / original_size
	set_scale(Vector2(1,1)*new_scale)
