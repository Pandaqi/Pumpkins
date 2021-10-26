extends Node2D

onready var body = get_parent()

var color : Color = Color(1.0, 1.0, 0.0)
var pumpkin_orange = Color(1.0, 93/255.0, 32/255.0)
var disabled : bool = false
var is_huge : bool = false

onready var shape_manager = get_node("/root/Main/ShapeManager")

func set_color(col):
	color = col

func use_huge_coloring():
	is_huge = true

func use_regular_coloring():
	is_huge = false

func disable():
	disabled = true
	update()

func enable():
	disabled = false
	update()

func _draw():
	if disabled: return
	
	var num_shapes = body.shape_owner_get_shape_count(0)
	var outline_layer = []
	var bottom_layer = []
	var middle_layer = []
	var middle_layer_2 = []
	var top_layer = []
	
	var thresholds = [0.9,0.8,0.65,0.3]
	if is_huge:
		thresholds = [0.98,0.92,0.78,0.55]
	
	for i in range(num_shapes):
		var points = Array(body.shape_owner_get_shape(0, i).points)
		
		outline_layer.append(points)
		bottom_layer.append(shape_manager.scale_shape(points, thresholds[0]))
		middle_layer.append(shape_manager.scale_shape(points, thresholds[1]))
		middle_layer_2.append(shape_manager.scale_shape(points, thresholds[2]))
		top_layer.append(shape_manager.scale_shape(points, thresholds[3]))
	
	var outline_color = Color(0.0, 0.0, 0.0, 1.0)
	for i in range(num_shapes):
		draw_polygon(outline_layer[i], [outline_color])
	
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
