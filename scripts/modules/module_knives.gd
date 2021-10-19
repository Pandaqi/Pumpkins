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
var use_curve : bool = false

onready var body = get_parent()
onready var map = get_node("/root/Main/Map")
onready var guide = $Guide

func create_starting_knives():
	for _i in range(NUM_STARTING_KNIVES):
		create_new_knife()
	
	loading_done = true
	randomly_position_knives()

func make_boomerang():
	for knife in knives_held:
		knife.get_node("ShadowLocation").type = "circle"
	
	are_boomerang = true

func undo_boomerang():
	for knife in knives_held:
		knife.get_node("ShadowLocation").type = "rect"
	
	are_boomerang = false

func create_new_knife():
	var knife = knife_scene.instance()
	knife.get_node("Sprite").set_frame(body.modules.status.player_num)
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
	
	var projectile = knife.get_node("Projectile")
	projectile.set_owner(body)
	projectile.being_held = true
	projectile.reset()
	
	var income_vec = (knife.get_global_position() - body.get_global_position()).normalized()
	
	if knife.get_parent(): knife.get_parent().remove_child(knife)
	add_child(knife)
	
	var snap_vec = income_vec.rotated(-body.rotation)
	if loading_done:
		snap_vec = snap_vec_to_knife_angles(snap_vec)

	var new_position = snap_vec * get_radius()
	var new_rotation = snap_vec.angle()

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

func move_first_knife_to_back():
	var first = knives_held.pop_front()
	knives_held.append(first)
	
	unhighlight_knife(first)
	highlight_first_knife()

func throw_knife(knife):
	knives_held.erase(knife)
	knives_thrown.append(knife)
	
	var projectile = knife.get_node("Projectile")
	projectile.being_held = false
	
	if use_curve:
		projectile.make_curving(body.modules.slasher.get_curve_strength())
	
	if are_boomerang:
		projectile.make_boomerang()
	
	unsnap_knife_angle(knife.rotation)
	
	var original_position = knife.get_global_position()
	var original_rotation = body.rotation + knife.rotation
	
	remove_child(knife)
	map.knives.add_child(knife)
	
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
	
	var first_knife = knives_held[0]
	
	first_knife.modulate = Color(1,0,0)
	
	guide.set_position(first_knife.get_position())
	guide.set_rotation(first_knife.get_rotation())

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
	
	print(snap_angles_taken)
	
	return Vector2(cos(ang), sin(ang))

func randomly_position_knives():
	var center = Vector2.ZERO
	var radius = get_radius()
	
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
	var radius = get_radius()
	
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

func get_radius():
	return 1.25 * body.modules.shaper.approximate_radius()

func is_mine(other_body):
	if (other_body in knives_thrown): return true
	if other_body.get_node("Projectile").has_no_owner(): return true
	if same_team(other_body.get_node("Projectile").my_owner): return true
	
	return false

func same_team(other_body):
	var our_team = body.modules.status.team_num
	var their_team = other_body.modules.status.team_num
	return (our_team == their_team)

func _on_Shaper_shape_updated():
	reposition_knives()

func destroy_knives():
	for knife in knives_held:
		knife.queue_free()
	
	knives_held = []

func disable_pickup():
	pickup_disabled = true
