extends Node

var STARTING_PLAYER_SIZE : float = 140.0

var predefined_shape_scene = preload("res://scenes/predefined_shape_list.tscn")
var available_shapes = []

var pumpkin_shape_scene = preload("res://PumpkinShapes.tscn")
var pumpkin_shapes = []

onready var players = get_node("/root/Main/Players")

func activate():
	determine_starting_size()
	
	load_predefined_shapes()
	load_pumpkin_shapes()
	
	available_shapes = GlobalDict.predefined_shapes.keys()

func determine_starting_size():
	var num_players = players.count_total_num_players()
	var threshold = 4
	if num_players > threshold:
		STARTING_PLAYER_SIZE -= 10.0*(num_players - threshold)

func load_pumpkin_shapes():
	var arr = []
	
	var ps = pumpkin_shape_scene.instance()
	for child in ps.get_children():
		if not (child is CollisionPolygon2D): continue
		arr.append(scale_shape_absolutely(Array(child.polygon), STARTING_PLAYER_SIZE))
		
	pumpkin_shapes = arr

func select_random_pumpkin_shape():
	return pumpkin_shapes[randi() % pumpkin_shapes.size()]

func select_random_predefined_shape():
	return GlobalDict.predefined_shapes[get_random_shape()].points

func get_random_shape():
	return available_shapes[randi() % available_shapes.size()]

# Predefined shapes
func load_predefined_shapes():
	var list = predefined_shape_scene.instance()
	var shape_size = STARTING_PLAYER_SIZE
	
	# ModeManager not loaded yet, need to grab it this way
	var mode_data = GlobalDict.modes[GlobalDict.cfg.game_mode]
	if mode_data.has("starting_shape_scale"):
		shape_size *= mode_data.starting_shape_scale
	
	for child in list.get_children():
		if not (child is CollisionPolygon2D): continue
		
		var temp_shape_size = shape_size
		if child.name == "Square" or child.name == "Circle":
			temp_shape_size *= 0.9
		
		var key = child.name.to_lower()
		var val = scale_shape_absolutely( Array(child.polygon), shape_size)

		GlobalDict.predefined_shapes[key].points = val

# Shape scaling
# NOTE: Points are already around centroid, and shaper node will do that again anyway, so just scale only
func scale_shape(points, val : float = 1.0):
	var new_points = []
	for p in points:
		new_points.append(p * val)
	return new_points

func scale_shape_absolutely(points, new_max_size : float):
	var b = get_bounding_box(points)
	var cur_max_size = max(abs(b.x.max) + abs(b.x.min), abs(b.y.max) + abs(b.y.min))

	var ratio = new_max_size / cur_max_size
	return scale_shape(points, ratio)

func get_bounding_box(points):
	var b = {
		'x': {'min': INF, 'max': -INF },
		'y': {'min': INF, 'max': -INF }
	}
	
	for p in points:
		b.x.min = min(b.x.min, p.x)
		b.x.max = max(b.x.max, p.x)
		
		b.y.min = min(b.y.min, p.y)
		b.y.max = max(b.y.max, p.y)
	
	return b

func get_bounding_box_shape_list(shape_list):
	var b = {
		'x': {'min': INF, 'max': -INF },
		'y': {'min': INF, 'max': -INF }
	}
	
	for shape in shape_list:
		var b2 = get_bounding_box(shape)
		
		b.x.min = min(b.x.min, b2.x.min)
		b.x.max = max(b.x.max, b2.x.max)
		b.y.min = min(b.y.min, b2.y.min)
		b.y.max = max(b.y.max, b2.y.max)
	
	return b

# Area calculation
func calculate_area(shape_list):
	var area = 0
	
	for shp in shape_list:
		area += calculate_shape_area_shoelace(shp)
	
	return area

func calculate_shape_area_shoelace(shp):
	var A = 0
	
	for i in range(shp.size()):
		var next_index = (i+1) % int(shp.size())
		var p1 = shp[i]
		var p2 = shp[next_index]
		
		A += p1.x * p2.y - p1.y * p2.x
	
	return abs(A * 0.5)
