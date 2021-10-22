extends Node2D

const BODY_SAFE_SCALE : float = 1.2

onready var nav_2d = $Navigation2D

func _ready():
	build_navigation_mesh()

func move_into_bounds(p):
	var epsilon = 0.0001
	if p.x <= epsilon:
		p.x = epsilon
	elif p.x >= 1920.0 - epsilon:
		p.x = 1920.0 - epsilon
	
	if p.y <= epsilon:
		p.y = epsilon
	elif p.y >= 1080.0 - epsilon:
		p.y = 1080.0 - epsilon
	
	return p

func scale_shape(shape, val : float = 1.0):
	for i in range(shape.size()):
		shape[i] = shape[i] * val
	
	return shape

func make_global(shape, trans):
	for i in range(shape.size()):
		shape[i] = trans.xform(shape[i])
		shape[i] = move_into_bounds(shape[i])
		
	return shape

func create_circle_polygon(radius):
	var num_steps : float = 16
	var ang_step = 2*PI / float(num_steps)
	var arr = []
	
	for i in range(num_steps):
		var rot = ang_step * i
		var point = Vector2(cos(rot), sin(rot))*radius
		arr.append(point)
	
	return arr

func build_navigation_mesh():
	var nav_poly_node = NavigationPolygonInstance.new()
	var nav_poly = NavigationPolygon.new()
	
	var full_screen = PoolVector2Array([Vector2(0,0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)])
	nav_poly.add_outline(full_screen)
	
	for child in get_children():
		if not (child is StaticBody2D): continue
		
		var polygon = null
		
		for new_child in child.get_children():
			var trans = new_child.get_global_transform()
			
			if new_child is CollisionShape2D:
				var col_shape = new_child.shape
				if col_shape is CircleShape2D:
					polygon = make_global(scale_shape(create_circle_polygon(col_shape.radius), BODY_SAFE_SCALE), trans)
					nav_poly.add_outline(PoolVector2Array(polygon))
					
					print("ADDED POLYGON")
					print(polygon)
			
			elif new_child is CollisionPolygon2D:
				polygon = make_global(scale_shape(new_child.polygon, BODY_SAFE_SCALE), trans)
				nav_poly.add_outline(PoolVector2Array(polygon))
		
	nav_poly.make_polygons_from_outlines()
	nav_poly_node.navpoly = nav_poly
	nav_2d.add_child(nav_poly_node)
