extends Node2D

onready var body = get_parent()

var color : Color = Color(1.0, 1.0, 0.0)
var pumpkin_orange = Color(1.0, 93/255.0, 32/255.0)

onready var shape_manager = get_node("/root/Main/ShapeManager")

func set_color(col):
	color = col

func _draw():
	var num_shapes = body.shape_owner_get_shape_count(0)
	var bottom_layer = []
	var middle_layer = []
	var middle_layer_2 = []
	var top_layer = []
	
	for i in range(num_shapes):
		var points = Array(body.shape_owner_get_shape(0, i).points)
		
		bottom_layer.append(points)
		middle_layer.append(shape_manager.scale_shape(points, 0.9))
		middle_layer_2.append(shape_manager.scale_shape(points, 0.75))
		top_layer.append(shape_manager.scale_shape(points, 0.33))
	
	for i in range(num_shapes):
		draw_polygon(bottom_layer[i], [color.darkened(0.7)])
	
	for i in range(num_shapes):
		draw_polygon(middle_layer[i], [color.darkened(0.5)])
	
	for i in range(num_shapes):
		draw_polygon(middle_layer_2[i], [color.darkened(0.3)])
	
	for i in range(num_shapes):
		draw_polygon(top_layer[i], [color])

func _on_Shaper_shape_updated():
	update()
