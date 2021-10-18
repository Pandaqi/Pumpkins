extends Node2D

const NUM_STARTING_KNIVES : int = 3

var knives_held = []
var knives_thrown = []

var knife_scene = preload("res://scenes/knife_bodyless.tscn")
var pickup_disabled : bool = false

var num_snap_angles : int = 24
var snap_angles_taken = []

var loading_done : bool = false
var are_boomerang : bool = false

onready var body = get_parent()
onready var main_node = get_node("/root/Main")

func create_starting_knives():
	for i in range(NUM_STARTING_KNIVES):
		create_new_knife()
	
	loading_done = true
	randomly_position_knives()

func create_new_knife():
	var knife = knife_scene.instance()
	add_child(knife)
	grab_knife(knife)

func destroy_random_knife():
	if knives_held.size() <= 0: return
	
	var rand_knife = knives_held[randi() % knives_held.size()]
	knives_held.erase(rand_knife)
	rand_knife.queue_free()

func grab_knife(knife):
	if pickup_disabled: return
	
	knives_thrown.erase(knife)
	knives_held.append(knife)
	
	knife.get_node("Projectile").set_owner(body)
	knife.get_node("Projectile").being_held = true
	
	var income_vec = (knife.get_global_position() - body.get_global_position()).normalized()
	
	if knife.get_parent(): knife.get_parent().remove_child(knife)
	add_child(knife)
	
	var snap_vec
	if not loading_done: 
		snap_vec = income_vec
	else:
		snap_vec = snap_vec_to_knife_angles(income_vec)

	var new_position = snap_vec.rotated(-body.rotation) * body.modules.shaper.approximate_radius()
	var new_rotation = snap_vec.angle() - body.rotation

	knife.set_position(new_position)
	knife.set_rotation(new_rotation)
	
	highlight_first_knife()

func throw_first_knife():
	if knives_held.size() <= 0: return null # TO DO: Feedback "KNIFE ICON, QUESTION MARK"
	
	throw_knife(knives_held[0])

func get_first_knife_vec():
	if knives_held.size() <= 0: return null
	
	var ang = knives_held[0].rotation + body.rotation
	return Vector2(cos(ang), sin(ang))

func throw_knife(knife):
	knives_held.erase(knife)
	knives_thrown.append(knife)
	
	knife.get_node("Projectile").being_held = false
	
	unsnap_knife_angle(knife.rotation)
	
	var original_position = knife.get_global_position()
	var original_rotation = body.rotation + knife.rotation
	
	remove_child(knife)
	main_node.add_child(knife)
	
	knife.set_rotation(original_rotation)
	knife.set_position(original_position)
	
	var dir = Vector2(cos(original_rotation), sin(original_rotation))
	knife.get_node("Projectile").throw(dir * body.modules.slasher.get_throw_strength())
	
	unhighlight_knife(knife)
	highlight_first_knife()

func unhighlight_knife(knife):
	knife.modulate = Color(1,1,1)

func highlight_first_knife():
	if knives_held.size() <= 0: return
	
	knives_held[0].modulate = Color(1,0,0)

#
# Positioning the knives
#
func unsnap_knife_angle(rot):
	var epsilon = 0.03
	var ang_index : int = floor((rot + epsilon) / (2*PI) * num_snap_angles)
	snap_angles_taken.erase(ang_index)

func snap_vec_to_knife_angles(vec):
	var epsilon = 0.03
	var ang_index : int = floor((vec.angle() + epsilon) / (2*PI) * num_snap_angles)
	while (ang_index in snap_angles_taken):
		ang_index = (ang_index + 1) % int(num_snap_angles)
	
	snap_angles_taken.append(ang_index)
	var ang = ang_index / float(num_snap_angles) * (2*PI)
	
	return Vector2(cos(ang), sin(ang))

func randomly_position_knives():
	var center = Vector2.ZERO
	var radius = body.modules.shaper.approximate_radius()
	
	var ang : float = 0.0
	var num_knives : int = knives_held.size()
	for knife in knives_held:
		var vec = snap_vec_to_knife_angles(Vector2(cos(ang), sin(ang)))
		knife.set_position(center + vec*radius)
		knife.set_rotation(vec.angle())
		
		ang += (2*PI / float(num_knives))

# When we've been sliced (or we've grown), the knives need to reposition
# Just keep their angle, but match the new radius
func reposition_knives():
	var center = Vector2.ZERO
	var radius = body.modules.shaper.approximate_radius()
	
	for knife in knives_held:
		var ang = knife.get_rotation()
		var vec = Vector2(cos(ang), sin(ang))
		knife.set_position(center + vec*radius)

#func reposition_knives():
#	var angle_between_knives = 0.25*PI
#	var angle_offset = -0.5 * (knives_held.size() - 1) * angle_between_knives
#
#	var center = Vector2.ZERO
#	var radius = body.modules.shaper.approximate_radius()
#
#	var counter : int = 0
#	for knife in knives_held:
#		var ang = angle_offset + counter*angle_between_knives
#		knife.set_position(center + Vector2(cos(ang), sin(ang))*radius)
#		knife.set_rotation(ang)
#
#		counter += 1

func is_mine(body):
	return (body in knives_thrown) or body.get_node("Projectile").has_no_owner()

func _on_Shaper_shape_updated():
	reposition_knives()

func destroy_knives():
	for knife in knives_held:
		knife.queue_free()
	
	knives_held = []

func disable_pickup():
	pickup_disabled = true
