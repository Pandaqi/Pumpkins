extends Node2D

const MAX_KNIVES : int = 8
const AUTO_THROW_INTERVAL : float = 5.0

var knives_held = []

var knife_scene = preload("res://scenes/knife_bodyless.tscn")
var pickup_disabled : bool = false

var num_snap_angles : int = 8
var snap_angles_taken = []
var knives_by_snap_angle = {}

var loading_done : bool = false
var cur_autothrow_time : float = 0.0

var are_boomerang : bool = false
var use_curve : bool = false

onready var body = get_parent()
onready var map = get_node("/root/Main/Map")
onready var guide = $Guide
onready var timer = $Timer

func activate():
	if GlobalDict.cfg.auto_throw_knives:
		_on_Timer_timeout()
	else:
		$AutoThrow.set_visible(false)
	
	if not GlobalDict.cfg.show_guides:
		guide.queue_free()
		guide = null
	
	create_starting_knives()

func _on_Timer_timeout():
	# mostly to prevent throwing knife immediately on game start
	if knives_held.size() > 0:
		throw_first_knife()
	
	timer.wait_time = get_random_throw_interval()
	cur_autothrow_time = timer.wait_time
	timer.start()

func _on_Slasher_slash_range_changed(s):
	$AutoThrow.set_scale(s)

func scale_autothrow_indicator():
	if not GlobalDict.cfg.auto_throw_knives: return
	
	var ratio = 1.0 - (timer.time_left / cur_autothrow_time)
	$AutoThrow/Sprite.set_scale(Vector2(1,1)*ratio)

func _physics_process(dt):
	scale_autothrow_indicator()

func get_random_throw_interval():
	return AUTO_THROW_INTERVAL * (0.8 + randf()*0.4)

func create_starting_knives():
	for _i in range(GlobalDict.cfg.num_starting_knives):
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

func move_knife(knife, new_ang):
	unsnap_knife_angle(knife.rotation)
	
	# if taken, SWITCH the knives first
	# NOTE: for that, we need to unsnap first, otherwise the new one won't move (as the old location is already taken)
	var ang_index = snap_ang_to_index(new_ang)
	if (ang_index in snap_angles_taken):
		var other_knife = knives_by_snap_angle[ang_index]
		move_knife(other_knife, knife.rotation)
		
	# then move to the new location
	var vec = Vector2(cos(new_ang), sin(new_ang))
	var new_position = vec * get_radius()

	knife.set_position(new_position)
	knife.set_rotation(new_ang)

func lose_random_knife():
	if knives_held.size() <= 0: return
	
	var rand_knife = knives_held[randi() % knives_held.size()]
	unsnap_knife_angle(rand_knife.rotation)
	knives_held.erase(rand_knife)
	rand_knife.queue_free()

func count():
	return knives_held.size()

func grab_knife(knife):
	var at_max_capacity = (knives_held.size() >= MAX_KNIVES)
	if at_max_capacity: return
	if pickup_disabled: return
	
	knives_held.append(knife)
	
	var projectile = knife.get_node("Projectile")
	projectile.set_owner(body)
	projectile.being_held = true
	projectile.reset()
	
	var income_vec = (knife.get_global_position() - body.get_global_position()).normalized()
	
	if knife.get_parent(): knife.get_parent().remove_child(knife)
	add_child(knife)
	
	knife.show_behind_parent = false
	
	var snap_vec = income_vec.rotated(-body.rotation)
	if loading_done:
		snap_vec = snap_vec_to_knife_angles(knife, snap_vec)

	var new_position = snap_vec * get_radius()
	var new_rotation = snap_vec.angle()

	knife.set_position(new_position)
	knife.set_rotation(new_rotation)
	
	knife.modulate.a = 0.5
	
	highlight_first_knife()

func throw_first_knife():
	if knives_held.size() <= 0: return null # TO DO: Feedback "KNIFE ICON, QUESTION MARK"
	
	throw_knife(knives_held[0])

func get_first_knife_vec():
	if knives_held.size() <= 0: return Vector2.ZERO
	
	var ang = knives_held[0].rotation + body.rotation
	return Vector2(cos(ang), sin(ang))

func move_first_knife_to_back():
	var first = knives_held.pop_front()
	knives_held.append(first)
	
	unhighlight_knife(first)
	highlight_first_knife()

func throw_knife(knife):
	if knife_overlaps_problematic_body(knife): return
	
	knives_held.erase(knife)
	
	var projectile = knife.get_node("Projectile")
	projectile.being_held = false
	projectile.set_owner(body)
	
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
	
	knife.modulate.a = 1.0
	
	var use_full_strength = GlobalDict.cfg.auto_throw_knives
	var dir = Vector2(cos(original_rotation), sin(original_rotation))
	knife.get_node("Projectile").throw(dir * body.modules.slasher.get_throw_strength(use_full_strength))
	
	unhighlight_knife(knife)
	highlight_first_knife()

func unhighlight_knife(knife):
	knife.get_node("AnimationPlayer").stop(true)
	knife.get_node("Sprite").modulate = Color(1,1,1,1)
	
	if guide:
		guide.set_visible(false)

func highlight_first_knife():
	if knives_held.size() <= 0: return
	
	var first_knife = knives_held[0]
	first_knife.get_node("AnimationPlayer").play("Highlight")

	if guide:
		guide.set_visible(true)
		guide.set_position(first_knife.get_position())
		guide.set_rotation(first_knife.get_rotation())
	
	if GlobalDict.cfg.knife_always_in_front:
		move_knife(first_knife, 0)

#
# Positioning the knives
#
func unsnap_knife_angle(rot):
	var epsilon = 0.03
	var ang_index : int = floor((rot + epsilon) / (2*PI) * num_snap_angles)
	knives_by_snap_angle.erase(ang_index)
	snap_angles_taken.erase(ang_index)

func snap_ang_to_index(ang):
	var epsilon = 0.03
	return floor((ang + epsilon) / (2*PI) * num_snap_angles)

func snap_ang(ang):
	var ang_index = snap_ang_to_index(ang)
	return ang_index / float(num_snap_angles) * (2*PI)

func snap_vec_to_knife_angles(knife, vec):
	var ang_index : int = snap_ang_to_index(vec.angle())
	while (ang_index in snap_angles_taken):
		ang_index = (ang_index + 1) % int(num_snap_angles)
	
	snap_angles_taken.append(ang_index)
	knives_by_snap_angle[ang_index] = knife
	var ang = ang_index / float(num_snap_angles) * (2*PI)
	
	return Vector2(cos(ang), sin(ang))

func randomly_position_knives():
	var center = Vector2.ZERO
	var radius = get_radius()
	
	var ang : float = 0.0
	var num_knives : int = knives_held.size()
	for knife in knives_held:
		var vec = snap_vec_to_knife_angles(knife, Vector2(cos(ang), sin(ang)))
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
	if other_body.get_node("Projectile").has_no_owner(): return true
	if same_team(other_body.get_node("Projectile").get_owner()): return true
	
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

func knife_overlaps_problematic_body(knife):
	var space_state = get_world_2d().direct_space_state
	var half_size = knife.get_node("Projectile").knife_half_size
	
	var shp = RectangleShape2D.new()
	shp.extents = Vector2(half_size, 0.25*half_size)
	
	var query_params = Physics2DShapeQueryParameters.new()
	query_params.set_shape(shp)
	
	query_params.transform = query_params.transform.rotated(knife.global_rotation)
	query_params.transform.origin = knife.get_global_position()
	
	var result = space_state.intersect_shape(query_params)
	if result:
		for obj in result:
			if not obj.collider.is_in_group("Sliceables"): return true
	
	return false
