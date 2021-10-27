extends StaticBody2D

const REPULSE_STRENGTH : float = 5.0

const ROTATING_TARGET_PROBABILITY : float = 0.33
const ROTATE_SPEED : float = 1.6

const RADIUS : float = 48.0
const LINE_THICKNESS : float = 5.0
const DIVISION_LINE_COLOR : Color = Color(64/255.0, 4/255.0, 0.0)
const POINT_BOUNDS = { 'min': -2, 'max': 5 }

const DIST_PER_POINT_UPGRADE : float = 300.0

var division_angles = []
var division_points = []

onready var map = get_node("/root/Main/Map")

var target_label_scene = preload("res://scenes/mode_modules/target_label.tscn")
var is_rotating : bool = false

var num_hits : int = 0
var knives_inside = []

func _ready():
	create_divisions()
	place_labels()
	update()
	make_rotating()

func make_rotating():
	if randf() > ROTATING_TARGET_PROBABILITY: return
	
	is_rotating = true

func _physics_process(dt):
	check_repulse_area()
	check_auto_rotating(dt)

func check_repulse_area():
	var bodies = $Area2D.get_overlapping_bodies()
	for b in bodies:
		if not b.is_in_group("Players"): continue
		
		var away_vec = (b.get_global_position() - get_global_position())
		b.modules.knockback.apply(away_vec * REPULSE_STRENGTH)

func check_auto_rotating(dt):
	if not is_rotating: return
	rotate(ROTATE_SPEED*dt)

func get_random_point_val():
	var rand = randi() % (POINT_BOUNDS.max - POINT_BOUNDS.min) + POINT_BOUNDS.min
	if rand == 0: rand = 1 if randf() <= 0.5 else -1
	return rand

func create_divisions():
	var total_ang = 0
	while total_ang < (1.75*PI):
		division_angles.append(total_ang)
		division_points.append(get_random_point_val())
		
		var ang_offset = randf()*(PI-0.33*PI) + 0.33*PI
		total_ang += ang_offset

func place_labels():
	var num_angles = division_angles.size()
	
	for i in range(num_angles):
		var my_ang = division_angles[i]
		var next_ang = division_angles[(i + 1) % int(num_angles)]
		if next_ang < my_ang:
			next_ang += (2*PI)
		
		var avg_ang = 0.5*(my_ang + next_ang)
		var radius = 0.66*RADIUS
		
		var label = target_label_scene.instance()
		label.get_node("Label").set_text(str(division_points[i]))
		add_child(label)
		
		label.set_position(Vector2(cos(avg_ang), sin(avg_ang))*radius)
		label.set_rotation(-rotation)

func on_knife_entered(body):
	var vec = (body.get_global_position() - get_global_position()).normalized()
	vec = vec.rotated(-rotation)
	var angle = vec.angle()
	
	if angle < 0: angle += 2*PI
	if angle >= 2*PI: angle -= 2*PI
	
	var division = get_division_from_angle(angle)
	var player = body.modules.owner.get_owner()
	
	var num_points = division_points[division]
	var multiplier = clamp(body.modules.thrower.get_distance_traveled() / DIST_PER_POINT_UPGRADE, 0.0, 3.0)
	if num_points < 0: multiplier = clamp(multiplier, 1.0, 3.0)
	
	num_points *= multiplier
	num_points = floor(num_points)
	
	player.modules.collector.collect(num_points)
	
	if is_rotating:
		var new_pos = vec * RADIUS

		body.get_parent().remove_child(body)
		add_child(body)
		move_child(body, 0)
		
		body.show_behind_parent = true
		
		body.set_position(new_pos)
		body.set_rotation(-vec.angle())
		
		knives_inside.append(body)
	
	num_hits += 1
	
	check_for_destroy()

func check_for_destroy():
	if num_hits < division_angles.size(): return
	
	for knife in knives_inside:
		var old_pos = knife.global_position
		
		remove_child(knife)
		map.knives.add_child(knife)
		
		knife.modules.mover.set_random_velocity()
		
		knife.set_position(old_pos)
	
	knives_inside = []
	self.queue_free()

func get_division_from_angle(ang):
	var num_angles : int = division_angles.size()
	
	for i in range(num_angles):
		var my_ang = division_angles[i]
		var next_ang = division_angles[(i + 1) % num_angles]
		
		if next_ang < my_ang: next_ang += 2*PI
		
		if ang >= my_ang and ang < next_ang:
			return i

func _draw():
	var from = Vector2.ZERO
	
	for ang in division_angles:
		var conv_ang = ang
		var to = from + Vector2(cos(conv_ang), sin(conv_ang))*RADIUS
		draw_line(from, to, DIVISION_LINE_COLOR, LINE_THICKNESS, true)
	
	
