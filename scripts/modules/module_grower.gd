extends Node

onready var body = get_parent()

func grow(val):
	if body.modules.shaper.at_max_size(): return
	change_size(1.0 + val)

func shrink(val):
	if body.modules.shaper.at_min_size(): return
	change_size(1.0 - val)

func change_size(factor):
	var num_shapes = body.shape_owner_get_shape_count(0)
	var shapes_to_add = []
	
	var center = body.get_global_position()
	var trans = body.get_global_transform()
	for i in range(num_shapes):
		var shape = body.shape_owner_get_shape(0, i)

		var pts = Array(shape.points)
		
		for a in range(pts.size()):
			pts[a] = ((trans.xform(pts[a]) - center) * factor).rotated(-body.rotation)
		
		shapes_to_add.append(pts)
	
	for shp in shapes_to_add:
		var new_shape = ConvexPolygonShape2D.new()
		new_shape.points = shp
		body.shape_owner_remove_shape(0, 0)
		body.shape_owner_add_shape(0, new_shape)

	body.modules.shaper.on_shape_updated()