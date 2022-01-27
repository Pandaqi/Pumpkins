extends Node2D

const AUTO_THROW_INTERVAL : float = 5.0

var max_knives : int
var knives_held = []

var pickup_disabled : bool = false

var num_snap_angles : int = 6
var snap_angles_taken = []
var knives_by_snap_angle = []

var loading_done : bool = false
var cur_autothrow_time : float = 0.0

var are_boomerang : bool = false
var use_curve : bool = false

onready var body = get_parent()
onready var map = get_node("/root/Main/Map")
onready var throwables = get_node("/root/Main/Throwables")
onready var particles = get_node("/root/Main/Particles")
onready var mode = get_node("/root/Main/ModeManager")
onready var guide = $Guide
onready var timer = $Timer

onready var reloader = $Reloader

var disabled : bool = false

func activate():
	if GlobalDict.cfg.auto_throw_knives:
		_on_Timer_timeout()
	else:
		$AutoThrow.set_visible(false)
	
	if not GlobalDict.cfg.show_guides:
		guide.queue_free()
		guide = null
	else:
		guide.get_node("Sprite").material = guide.get_node("Sprite").material.duplicate(true)
		guide.get_node("Sprite").material.set_shader_param('progress', 0.0)
	
	max_knives = mode.get_max_knife_capacity()
	knives_by_snap_angle.resize(num_snap_angles)
	
	create_starting_knives()

func _on_Timer_timeout():
	if disabled: return
	
	# mostly to prevent throwing knife immediately on game start
	if knives_held.size() > 0:
		throw_first_knife()
	
	timer.wait_time = get_random_throw_interval()
	cur_autothrow_time = timer.wait_time
	timer.start()

func has_no_knives():
	return knives_held.size() <= 0

func has_type(type : String):
	for knife in knives_held:
		if knife.modules.status.type == type: return true
	
	return false

func check_dumpling_hit(dumpling, attacker):
	var type = dumpling.modules.status.type
	
	if type == "dumpling_poisoned":
		attacker.modules.powerups.grab(null, type, "reverse")
		attacker.modules.knives.lose_random()
	
	if not mode.inverted_dumpling_behaviour(): return

	throwables.create_new_for(attacker, type)
	remove_specific(dumpling)

func _on_Slasher_slash_range_changed(s):
	$AutoThrow.set_scale(s)

func scale_autothrow_indicator():
	if not GlobalDict.cfg.auto_throw_knives: return
	
	var ratio = 1.0 - (timer.time_left / cur_autothrow_time)
	$AutoThrow/Sprite.set_scale(Vector2(1,1)*ratio)

func _physics_process(_dt):
	scale_autothrow_indicator()

func get_random_throw_interval():
	return AUTO_THROW_INTERVAL * (0.8 + randf()*0.4)

func create_starting_knives():
	var starting_type = GlobalDict.cfg.starting_throwable_type
	var num_starting_knives = GlobalDict.cfg.num_starting_knives
	
	for _i in range(num_starting_knives):
		throwables.create_new_for(body, starting_type)
	
	loading_done = true
	randomly_position_knives()

func move_knife(knife, new_ang):
	if not knife or not is_instance_valid(knife): return
	
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
	
	snap_vec_to_knife_angles(knife, vec)

func lose_random():
	if knives_held.size() <= 0: return
	
	var rand_knife = knives_held[randi() % knives_held.size()]
	remove_specific(rand_knife)

func remove_specific(obj):
	unhighlight_knife(obj)
	highlight_first_knife()
	
	check_for_collectibles(obj, -1)
	
	unsnap_knife_angle(obj.rotation)
	knives_held.erase(obj)
	obj.modules.status.delete()

func count():
	return knives_held.size()

func at_max_capacity(body = null):
	var max_cap = (knives_held.size() >= max_knives)
	if max_cap and body and body.modules.has('particles'): body.modules.particles.continuous_feedback("Full!")
	return max_cap

func grab_knife(knife):
	if at_max_capacity(body): return
	if pickup_disabled: return
	if disabled: return
	
	knives_held.append(knife)
	
	var income_vec = (knife.get_global_position() - body.get_global_position()).normalized()
	
	if knife.get_parent(): knife.get_parent().remove_child(knife)
	add_child(knife)
	
	knife.show_behind_parent = false
	
	var snap_vec = income_vec.rotated(-body.rotation)
	if loading_done:
		snap_vec = snap_vec_to_knife_angles(knife, snap_vec)
		GlobalAudio.play_dynamic_sound(body, "grab")

	var new_position = snap_vec * get_radius()
	var new_rotation = snap_vec.angle()

	knife.set_position(new_position)
	knife.set_rotation(new_rotation)
	
	knife.modulate.a = 0.5
	
	body.modules.slasher.reset_idle_timer()
	
	# check for types that do something special to us
	var val = +1
	var type = knife.modules.status.type
	if type == "dumpling_double":
		val = 2
		body.modules.grower.grow(0.2)
	elif type == "dumpling_downgrade":
		val = -1
		body.modules.grower.shrink(0.2)
	elif type == "dumpling_timebomb":
		knife.modules.timebomb.activate()
	
	check_for_collectibles(knife, val)
	
	if loading_done:
		highlight_first_knife()

func check_for_collectibles(obj, change):
	var col_group = mode.get_collectible_group()
	if not col_group: return
	if not obj.is_in_group(col_group): return
	if body.modules.status.team_num < 0: return
	
	body.modules.collector.collect(change)

# TO DO: what ... should we actually do here?
func cancel_throw():
	pass

func throw_first_knife():
	var first_knife = get_first_knife()
	if not first_knife: 
		particles.general_feedback(body.global_position, "Empty!")
		return
	
	throw_knife(first_knife)

func get_first_knife_vec():
	var first_knife = get_first_knife()
	if not first_knife: return Vector2.ZERO
	
	var ang = knives_held[0].rotation + body.rotation
	return Vector2(cos(ang), sin(ang))

func move_first_knife_to_back():
	var first = knives_held.pop_front()
	knives_held.append(first)
	
	unhighlight_knife(first)
	highlight_first_knife()

func is_reloading():
	return reloader.is_reloading

func play_throw_tween():
	body.modules.tween.interpolate_property(body, "scale", 
		Vector2.ONE*1.35, Vector2.ONE, 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	body.modules.tween.start()

func throw_knife(knife):
	if disabled: return
	if is_reloading(): 
		particles.general_feedback(body.global_position, "Reloading!")
		return
	
	play_throw_tween()
	
	if knife_overlaps_problematic_body(knife): return
	
	knives_held.erase(knife)
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

	var throw_strength = body.modules.slasher.get_throw_strength(use_full_strength)
	var final_throw_vec = dir * throw_strength
	
	knife.modules.thrower.throw(body, final_throw_vec)
	
	# check for types that do something special to us
	var val = -1
	var type = knife.modules.status.type
	if type == "dumpling_double":
		val = -2
	elif type == "dumpling_downgrade":
		val = +1
	elif type == "dumpling_timebomb":
		knife.modules.timebomb.deactivate()
	
	check_for_collectibles(knife, val)
	
	unhighlight_knife(knife)
	highlight_first_knife()
	
	if GlobalDict.cfg.limit_fire_rate:
		reloader.on_throw()

func unhighlight_knife(knife):
	knife.get_node("AnimationPlayer").stop(true)
	knife.get_node("Sprite").modulate = Color(1,1,1,1)
	
	if guide:
		guide.set_visible(false)

func update_guide_material(progress_ratio):
	if not guide or not is_instance_valid(guide): return
	
	guide.get_node("Sprite").material.set_shader_param('progress', progress_ratio)

func get_first_knife():
	if knives_held.size() <= 0: return
	
	var col_group = mode.get_collectible_group()
	if not col_group: return knives_held[0]
	
	# throwables that are also collectible can't be thrown
	# (as it would be useless and annoying, losing your collectible each time)
	for i in range(knives_held.size()):
		if knives_held[i].is_in_group(col_group): continue
		return knives_held[i]
	
	return null

func highlight_first_knife():
	var first_knife = get_first_knife()
	if not first_knife: return
	first_knife.get_node("AnimationPlayer").play("Highlight")

	if GlobalDict.cfg.knife_always_in_front:
		move_knife(first_knife, 0)

	if guide:
		guide.set_visible(true)
		guide.set_position(first_knife.get_position())
		guide.set_rotation(first_knife.get_rotation())
	
	

#
# Positioning the knives
#
func unsnap_knife_angle(rot):
	var ang_index = snap_ang_to_index(rot)
	
	knives_by_snap_angle[ang_index] = null
	snap_angles_taken.erase(ang_index)

func snap_ang_to_index(ang):
	var epsilon = 0.03
	var ang_index : int = int(round((ang + epsilon) / (2*PI) * num_snap_angles))
	ang_index = (ang_index + num_snap_angles) % num_snap_angles 
	return ang_index

func snap_ang(ang):
	var ang_index = snap_ang_to_index(ang)
	return ang_index / float(num_snap_angles) * (2*PI)

func snap_vec_to_knife_angles(knife, vec, override = true):
	var ang_index : int = snap_ang_to_index(vec.angle())
	while (ang_index in snap_angles_taken):
		ang_index = (ang_index + 1) % int(num_snap_angles)
	
	if override:
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
	
	highlight_first_knife()

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
	if disabled: return false
	
	if other_body.modules.owner.is_hostile(): return false
	if other_body.modules.owner.is_friendly(): return true
	if other_body.modules.owner.has_none(): return true
	
	var cur_owner = other_body.modules.owner.get_owner()
	if same_team(cur_owner): return true

	return false

func same_team(other_body):
	var our_team = body.modules.status.team_num
	var their_team = other_body.modules.status.team_num
	return (our_team == their_team)

func _on_Shaper_shape_updated():
	reposition_knives()

func destroy_knives():
	for knife in knives_held:
		unhighlight_knife(knife)
		knife.modules.status.delete()
	
	knives_held = []

func disable():
	disabled = true

func disable_pickup():
	pickup_disabled = true

func knife_overlaps_problematic_body(knife):
	var space_state = get_world_2d().direct_space_state
	var half_size = knife.modules.fakebody.knife_half_size
	
	var shp = RectangleShape2D.new()
	shp.extents = Vector2(half_size, 0.25*half_size)
	
	var query_params = Physics2DShapeQueryParameters.new()
	query_params.set_shape(shp)
	
	query_params.collision_layer = 1 + 4 + 8
	query_params.transform = query_params.transform.rotated(knife.global_rotation)
	query_params.transform.origin = knife.get_global_position()
	
	var result = space_state.intersect_shape(query_params)
	if result:
		for obj in result:
			var hit_body = obj.collider
			
			if hit_body == knife: continue
			if hit_body.is_in_group("Players"): continue
			if hit_body.is_in_group("Throwables"): continue
			if not hit_body.is_in_group("Sliceables"): return true
	
	return false
