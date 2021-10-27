extends Node2D

const MAX_CIRCLES : int = 5
const TRAVEL_SPEED : float = 40.0
const CIRCLE_TRAVEL_SPEED : float = 15.0
const RADI_BOUNDS = { 'min': 175, 'max': 275 }

var global_move_vec
var rect_size
var circles = []
var areas = []
onready var sprite = $Sprite

func _ready():
	create_areas()
	restart()

func create_areas():
	for i in range(MAX_CIRCLES):
		var a : Area2D = Area2D.new()
		a.collision_layer = 32
		a.collision_mask = 32
		
		var col = CollisionShape2D.new()
		a.add_child(col)
		
		var circle = CircleShape2D.new()
		col.shape = circle
		
		add_child(a)
		areas.append(a)
		
		a.connect("body_entered", self, "throwable_entered_mist")

func throwable_entered_mist(body):
	if not body.is_in_group("Throwables"): return

	var vel = body.modules.mover.get_velocity()
	var dir = -1 if randf() <= 0.5 else 1
	vel = vel.rotated(dir*(0.05 + randf()*0.125)*PI)
	body.modules.mover.set_velocity(vel)

func restart():
	# determine random outer bounds for mist
	var rand_rect_size = Vector2(randf(), randf())*200.0 + Vector2(1,1)*800.0
	var rect_scale = rand_rect_size / 64.0
	
	rect_size = rand_rect_size
	sprite.set_scale(rect_scale)
	sprite.material.set_shader_param("rect_size", rand_rect_size)
	
	# determine how we'll move globally
	# (also determines our starting pos)
	var index = (randi() % 4)
	var rand_rot = 0.25*PI + index*0.5*PI
	global_move_vec = -Vector2(cos(rand_rot), sin(rand_rot))
	
	var vp = Vector2(1920, 1080)
	var starting_pos
	
	if index == 0:
		starting_pos = vp + 0.5*rect_size
	if index == 1:
		starting_pos = Vector2(0,vp.y) + Vector2(-0.5,0.5)*rect_size
	elif index == 2:
		starting_pos = Vector2(0,0) - 0.5*rect_size
	elif index == 3:
		starting_pos = Vector2(vp.x, 0) + Vector2(0.5,-0.5)*rect_size

	global_move_vec = (0.5*vp-starting_pos).normalized()
	set_position(starting_pos)
	
	# place some circles
	var center_pos = 0.5*rand_rect_size
	circles.clear()
	for i in range(MAX_CIRCLES):
		var radius = get_random_radius()
		var obj = { 'num': i, 'pos': get_random_pos(radius), 'r': radius, 'vec': get_random_vec(), 'grow': get_random_grow() }
		circles.append(obj)
		visualize_circle(obj)

func _physics_process(dt):
	update_mist_itself(dt)
	move_whole_cloud(dt)

func update_mist_itself(dt):
	for i in range(circles.size()):
		move_circle(circles[i], dt)
		visualize_circle(circles[i])

func move_whole_cloud(dt):
	set_position(get_position() + TRAVEL_SPEED*global_move_vec*dt)
	
	if out_of_global_bounds(get_position()):
		restart()

func out_of_global_bounds(pos):
	var margin = -0.5*rect_size
	return pos.x < margin.x or pos.x > 1920.0 - margin.x or pos.y < margin.y or pos.y > 1080.0 - margin.y

func get_random_radius():
	return rand_range(RADI_BOUNDS.max, RADI_BOUNDS.min)

func get_random_pos(r):
	return Vector2(randf(), randf())*(rect_size-2*Vector2(1,1)*r) + Vector2(1,1)*r

func get_random_grow():
	return -1 if randf() <= 0.5 else 1

func get_random_vec():
	var rot = 2*PI*randf()
	return Vector2(cos(rot), sin(rot))

func move_circle(obj, dt):
	obj.pos += CIRCLE_TRAVEL_SPEED * obj.vec * dt
	obj.radius = clamp(obj.r + obj.grow*dt*30.0, RADI_BOUNDS.min, RADI_BOUNDS.max)
	
	if out_of_bounds(obj): 
		obj.vec *= -1
		obj.vec = obj.vec.rotated((randf() - 0.5)*PI)
	if at_extreme_radius(obj): obj.grow *= -1
	
	var my_area = areas[obj.num]
	var area_pos = obj.pos - 0.5*rect_size
	my_area.position = area_pos
	
	my_area.get_child(0).shape.radius = 0.66*obj.radius

func at_extreme_radius(obj):
	return obj.radius <= RADI_BOUNDS.min or obj.radius >= RADI_BOUNDS.max

func out_of_bounds(obj):
	var pos = obj.pos
	return pos.x <= obj.r or pos.x >= (rect_size.x - obj.r) or pos.y <= obj.r or pos.y >= (rect_size.y - obj.r)

func visualize_circle(obj):
	sprite.material.set_shader_param("p" + str(obj.num+1), obj.pos)
	sprite.material.set_shader_param("r" + str(obj.num+1), obj.r)
