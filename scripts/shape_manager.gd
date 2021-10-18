extends Node

const PREDEFINED_SHAPE_SCALE : float = 1.34

var predefined_shape_scene = preload("res://scenes/predefined_shape_list.tscn")
var available_shapes = []

func activate():
	load_predefined_shapes()
	
	available_shapes = GlobalDict.predefined_shapes.keys()

func get_random_shape():
	return available_shapes[randi() % available_shapes.size()]

# Predefined shapes
func load_predefined_shapes():
	var list = predefined_shape_scene.instance()
	for child in list.get_children():
		if not (child is CollisionPolygon2D): continue
		
		var key = child.name.to_lower()
		var val = scale_shape( Array(child.polygon) )

		GlobalDict.predefined_shapes[key].points = val

# NOTE: Points are already around centroid, and shaper node will do that again anyway, so just scale only
func scale_shape(points, val : float = PREDEFINED_SHAPE_SCALE):
	var new_points = []
	for p in points:
		new_points.append(p * val)
	return new_points
