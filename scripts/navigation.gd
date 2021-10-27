extends Node2D

const BODY_SAFE_MARGIN : float = 30.0 # 1.03 goes wrong

onready var nav_2d = $Navigation2D
onready var map = get_node("../Map")

var polygons = []
var debug_overlap_polygons = []

var debug_draw : bool = false

var full_screen_poly = PoolVector2Array([Vector2(0,0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])

func activate():
	build_navigation_mesh()

func move_into_bounds(p):
	var epsilon = 0.01
	if p.x <= 1.0 + epsilon:
		p.x = 1.0 + epsilon
	elif p.x >= 1920.0 - 1.0 - epsilon:
		p.x = 1920.0 - 1.0 - epsilon
	
	if p.y <= 1.0 + epsilon:
		p.y = 1.0 + epsilon
	elif p.y >= 1080.0 - 1.0 - epsilon:
		p.y = 1080.0 - 1.0 - epsilon
	
	return p

func scale_shape(shape, val : float = 1.0):
	return Geometry.offset_polygon_2d(shape, val)[0]

func make_global(shape, trans):
	for i in range(shape.size()):
		shape[i] = trans.xform(shape[i])
		
	return shape

func create_circle_polygon(radius):
	var num_steps : float = 8
	var ang_step = 2*PI / float(num_steps)
	var arr = []
	
	for i in range(num_steps):
		var rot = ang_step * i
		var point = Vector2(cos(rot), sin(rot))*radius
		arr.append(point)
	
	return arr

func create_rect_polygon(extents):
	return [-extents, Vector2(extents.x, -extents.y), extents, Vector2(-extents.x, extents.y)]

func convert_all_children(node):
	for N in node.get_children():
		if N.get_child_count() > 0:
			convert_all_children(N)
		else:
			convert_body_into_nav_mesh(N)

func convert_body_into_nav_mesh(node):
	if not (node.get_parent() is StaticBody2D): return
	if node.get_parent().is_in_group("IgnoreNavs"): return
	
	# DEBUGGING
	# if not node.is_visible(): return
	
	var is_col_shape = (node is CollisionShape2D)
	var is_col_poly = (node is CollisionPolygon2D)
	if not (is_col_shape or is_col_poly): return
	
	var polygon = null
	var trans = node.get_global_transform()
	
	if is_col_shape:
		var col_shape = node.shape
		if col_shape is CircleShape2D:
			polygon = make_global(scale_shape(create_circle_polygon(col_shape.radius), BODY_SAFE_MARGIN), trans)
		
		elif col_shape is RectangleShape2D:
			polygon = make_global(scale_shape(create_rect_polygon(col_shape.extents), BODY_SAFE_MARGIN), trans)
			
	elif is_col_poly:
		polygon = make_global(scale_shape(node.polygon, BODY_SAFE_MARGIN), trans)
	
	polygon = PoolVector2Array(polygon)
	
	var obj = {
		'poly': polygon,
		'parent': node,
		'body': node.get_parent()
	}
	polygons.append(obj)

func keep_shape_within_bounds(shp):
	for i in range(shp.size()):
		shp[i] = move_into_bounds(shp[i])
	return shp

func cut_holes_in_mesh(nav_poly):
	var index = 0
	for obj in polygons:
		debug_overlap_polygons.append(obj.poly)
		nav_poly.add_outline_at_index(obj.poly, index)
		
		if obj.body.is_in_group("DynamicNavigation"):
			obj.body.modules.navigation.set_data({
				'nav_poly': nav_poly,
				'outline': obj.poly,
				'index': index
			})
		
		index += 1

func merge_polygons():
	var num_polygons = polygons.size()

	var i = 0
	while i < num_polygons:
		var my_poly = polygons[i].poly
		
		var j = i
		while j < (num_polygons-1):
			j += 1
			
			var other_poly = polygons[j].poly
		
			# check if overlaps
			var no_overlap = (Geometry.intersect_polygons_2d(my_poly, other_poly).size() <= 0)
			if no_overlap: continue
			
			# if so, merge, start again
			var merged_poly = Geometry.merge_polygons_2d(my_poly, other_poly)
			
			polygons[i].poly = merged_poly[0]
			my_poly = merged_poly[0]
			
			polygons.remove(j)
			num_polygons -= 1

			j = i
		
		i += 1

func cut_offscreen_bits():
	var other_poly = full_screen_poly
	
	for i in range(polygons.size()-1,-1,-1):
		var my_poly = polygons[i].poly
		var intersect_polys = Geometry.intersect_polygons_2d(my_poly, other_poly)
		if intersect_polys.size() <= 0: continue

		polygons[i].poly = Geometry.offset_polygon_2d(intersect_polys[0], -0.2)[0]

func build_navigation_mesh():
	var nav_poly_node = NavigationPolygonInstance.new()
	var nav_poly = NavigationPolygon.new()
	
	var full_screen = full_screen_poly
	nav_poly.add_outline(full_screen)
	
	convert_all_children(map)
	merge_polygons()
	cut_offscreen_bits()
	cut_holes_in_mesh(nav_poly)
	
	nav_poly.make_polygons_from_outlines()
	nav_poly_node.navpoly = nav_poly
	nav_2d.add_child(nav_poly_node)
	
	update()

func _draw():
	if not debug_draw: return
	
	for poly in debug_overlap_polygons:
		draw_polygon(poly, [Color(1,1,1, 0.3)])
