extends Node2D

const NUM_STARTING_KNIVES : int = 1

var knives_held = []
var knives_thrown = []

var knife_scene = preload("res://scenes/knife.tscn")
var planned_knife_grab = null

onready var body = get_parent()
onready var main_node = get_node("/root/Main")

func create_starting_knives():
	for i in range(NUM_STARTING_KNIVES):
		var knife = knife_scene.instance()
		add_child(knife)
		knife.add_collision_exception_with(body)
		
		grab_knife(knife)
	
	reposition_knives()

func _process(_dt):
	if not planned_knife_grab: return
	
	grab_knife(planned_knife_grab)
	planned_knife_grab = null

func plan_knife_grab(body):
	planned_knife_grab = body

func grab_knife(knife):
	knife.collision_layer = 0
	knife.collision_mask = 0
	
	knife.set_linear_velocity(Vector2.ZERO)
	knife.set_angular_velocity(0)
	
	knife.set_mode(RigidBody2D.MODE_KINEMATIC)
	
	knives_thrown.erase(knife)
	knives_held.append(knife)
	
	knife.modules.projectile.being_held = true
	
	if knife.get_parent(): knife.get_parent().remove_child(knife)
	add_child(knife)
	
	reposition_knives()

func throw_first_knife(vec):
	if knives_held.size() <= 0: return # TO DO: Feedback "KNIFE ICON, QUESTION MARK"
	
	throw_knife(knives_held[0], vec)

func throw_knife(knife, dir : Vector2):
	knife.collision_layer = 1 + 4
	knife.collision_mask = 1 + 4
	
	knife.set_mode(RigidBody2D.MODE_RIGID)
	
	knives_held.erase(knife)
	knives_thrown.append(knife)
	
	knife.modules.projectile.being_held = false
	
	var original_position = knife.get_global_position()
	var original_rotation = body.rotation + knife.rotation
	
	remove_child(knife)
	main_node.add_child(knife)
	
	knife.set_rotation(original_rotation)
	knife.plan_teleport(original_position)
	knife.plan_shoot_away(dir * body.modules.slasher.get_throw_strength())
	
	reposition_knives()

func reposition_knives():
	var angle_between_knives = 0.25*PI
	var angle_offset = -0.5 * (knives_held.size() - 1) * angle_between_knives
	
	var center = Vector2.ZERO
	var radius = body.modules.shaper.approximate_radius()
	
	var counter : int = 0
	for knife in knives_held:
		var ang = angle_offset + counter*angle_between_knives
		knife.set_position(center + Vector2(cos(ang), sin(ang))*radius)
		knife.set_rotation(ang)
		
		counter += 1

func is_mine(body):
	return (body in knives_thrown)

func _on_Shaper_shape_updated():
	reposition_knives()
