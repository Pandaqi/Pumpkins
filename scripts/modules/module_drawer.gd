extends Node2D

onready var body = get_parent()

export var color : Color = Color(1.0, 1.0, 0.0)
export var use_multi_color : bool = true

var pumpkin_orange = Color(1.0, 93/255.0, 32/255.0)
var disabled : bool = false
var is_huge : bool = false
var smooth_outline_with_circles : bool = false

onready var shape_manager = get_node("/root/Main/ShapeManager")

func set_color(col):
	color = col

func set_multi_color(val):
	use_multi_color = val

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
	
	if GlobalDict.cfg.use_cartoony_coloring:
		cartoony_draw()
		return
	
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
	if not use_multi_color: outline_color = color
	
	for i in range(num_shapes):
		draw_polygon(outline_layer[i], [outline_color])
	
	if not use_multi_color: return
	
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

func cartoony_draw():
	var shape_list = body.modules.shaper.shape_list + []
	
	# pre-inflate all shapes (to ensure merges work)
	for i in range(shape_list.size()):
		shape_list[i] = Geometry.offset_polygon_2d(shape_list[i], 1.0)[0]
	
	# now keep merging with shapes until none left
	var counter = 1
	var full_polygon = shape_list[0]
	while shape_list.size() > 1 and counter < shape_list.size():
		var new_polygon = Geometry.merge_polygons_2d(full_polygon, shape_list[counter])
		
		# no succesful merge? continue
		if new_polygon.size() > 1:
			counter += 1
			continue
		
		# succes? save the merged polygon, remove the other from the list and start searching again
		full_polygon = new_polygon[0]
		shape_list.remove(counter)
		counter = 1
	
	var outline_margin = 0
	
	var outline_polygon = Geometry.offset_polygon_2d(full_polygon, outline_margin)[0]
	outline_polygon.append(outline_polygon[0])
	
	var outline_color = color.darkened(0.7)
	var outline_thickness = 5.0
	
	draw_polygon(full_polygon, [color])
	draw_polyline(outline_polygon, outline_color, outline_thickness, true)
	
	# NOTE: This is really slow + doesn't look good if things modulate their alpha
	# So only apply to players?
	if smooth_outline_with_circles:
		for point in outline_polygon:
			draw_circle(point, 0.5*outline_thickness, outline_color)
