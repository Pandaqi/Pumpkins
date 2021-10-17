extends Node2D

onready var body = get_parent()

var color : Color = Color(1.0, 1.0, 0.0)

func set_color(col):
	color = col

func _draw():
	var num_shapes = body.shape_owner_get_shape_count(0)
	for i in range(num_shapes):
		var points = Array(body.shape_owner_get_shape(0, i).points)
		draw_polygon(points, [color])

func _on_Shaper_shape_updated():
	update()
