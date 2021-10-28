extends Node

const MAX_AREA : float = 4500.0
const MIN_AREA : float = 400.0

var area : float = 0.0
var bounding_box : Dictionary = {}
var shape_list : Array = []

onready var body = get_parent()
onready var slicer = get_node("/root/Main/Slicer")
onready var shape_manager = get_node("/root/Main/ShapeManager")
onready var particles = get_node("/root/Main/Particles")

signal shape_updated()

# Shape creation
func destroy():
	var num_shapes = body.shape_owner_get_shape_count(0)
	for _i in range(num_shapes):
		body.shape_owner_remove_shape(0, 0)

func create_from_shape_list(shapes):
	# so that, visually, the body stays exactly the same 
	# (but under the hood, the shapes have changed, and the center of mass is correct)
	var avg = get_average_centroid(shapes)
	body.set_position(avg) 
	
	for i in range(shapes.size()):
		var shp = make_local(shapes[i])
		var shape_node = ConvexPolygonShape2D.new()
		shape_node.points = shp
		body.shape_owner_add_shape(0, shape_node)
	
	on_shape_updated()

func create_from_shape(shp):
	var shape = reposition_around_centroid(shp)
	body.modules.col.polygon = shape
	
	on_shape_updated()

func morph_to_random_shape():
	var rand_shape = shape_manager.get_random_shape()
	var points = GlobalDict.predefined_shapes[rand_shape].points
	
	var other_area : float = 5000.0 # most predefined shapes are roughly this area
	var scale_factor = area / other_area

	# limit the scale factor nonetheless, to prevent the "blowing up" bug :p
	scale_factor = clamp(scale_factor, 0.75, 1.25)

	points = shape_manager.scale_shape(points, scale_factor)

	destroy()
	create_from_shape(points)

func on_shape_updated():
	recalculate_shape_list()
	recalculate_area()
	recalculate_bounding_box()
	check_death()
	emit_signal("shape_updated")

func check_death():
	if not body.modules.status.can_die(): return
	
	var area_getting_dangerously_small = (area < (slicer.PLAYER_MIN_AREA_FOR_SHAPE + 900.0))
	if area_getting_dangerously_small:
		particles.general_feedback(body.global_position, "Almost dead!")
		body.modules.status.almost_dead()

# Area calculation
func at_max_size():
	return area >= MAX_AREA

func at_min_size():
	return area <= MIN_AREA

func get_size_as_ratio():
	return (area - MIN_AREA)/float(MAX_AREA - MIN_AREA)

func get_shape_list():
	return shape_list

func recalculate_shape_list():
	shape_list = []
	
	var num_shapes = body.shape_owner_get_shape_count(0)
	for i in range(num_shapes):
		var shape = body.shape_owner_get_shape(0, i)
		shape_list.append(shape.points)

func recalculate_bounding_box():
	bounding_box = shape_manager.get_bounding_box_shape_list(shape_list)

func recalculate_area():
	area = shape_manager.calculate_area(shape_list)

func approximate_radius():
	return sqrt(area / PI)

# Helper functions
func get_average_centroid(shp_list):
	var avg_centroid = Vector2.ZERO
	var num_points = 0
	for shape in shp_list:
		for point in shape:
			avg_centroid += point
			num_points += 1
	
	avg_centroid /= float(num_points)
	
	return avg_centroid

func make_local(shp):
	for i in range(shp.size()):
		shp[i] = (shp[i] - body.position).rotated(-body.rotation)
	
	return shp

func reposition_around_average_centroid(shape, avg_centroid):
	for i in range(shape.size()):
		shape[i] -= avg_centroid
	
	return shape

func reposition_around_centroid(shp, given_centroid = null):
	var centroid = given_centroid
	if not centroid:
		centroid = calculate_centroid(shp)
	
	for i in range(shp.size()):
		shp[i] = (shp[i] - centroid).rotated(-body.rotation)
	
	return shp

func calculate_centroid(shp):
	var avg = Vector2.ZERO
	for point in shp:
		avg += point
	
	return avg / float(shp.size())

func _on_StatTimer_timeout():
	body.modules.statistics.record("accumulated_size", area)
