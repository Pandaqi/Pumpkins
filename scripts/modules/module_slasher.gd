extends Node2D

const THROW_TIME_THRESHOLD : float = 220.0 # milliseconds
const QUICK_SLASH_COOLDOWN_DURATION : float = 3000.0 # milliseconds

const ROTATE_SPEED : float = 0.4*0.016
const AIM_INTERP_FACTOR : float = 0.25

onready var body = get_parent()
onready var slicer = get_node("/root/Main/Slicer")
onready var particles = get_node("/root/Main/Particles")
onready var map = get_node("/root/Main/Map")
onready var mode = get_node("/root/Main/ModeManager")

var player_num : int = -1
var slashing_enabled : bool = false

var slash_start_time : float
var last_quick_slash_time : float

const SLASH_RANGE_BOUNDS = { 'min': 70, 'max': 360 }
const DEFAULT_SLASH_RANGE = 150
var range_multiplier : float = 1.0
var slash_range : float
onready var range_sprite = $Sprite

const MAX_TIME_HELD : float = 800.0 # holding longer than this changing nothing anymore
const THROW_STRENGTH_BOUNDS = { 'min': 800, 'max': 2000 }
const BASE_THROW_STRENGTH : float = 1000.0
var strength_multiplier : float = 1.0

signal slash_range_changed(new_scale)
signal quick_slash()
signal thrown_slash()
signal aim()

func _ready():
	remove_child(range_sprite)
	map.ground.add_child(range_sprite)
	determine_slash_range()
	
	if not GlobalDict.cfg.show_guides:
		range_sprite.queue_free()
		range_sprite = null

func set_player_num(num):
	player_num = num
	range_sprite.set_frame(num)

func hide_range_sprite():
	if not range_sprite: return
	range_sprite.set_visible(false)

func show_range_sprite():
	if not range_sprite: return
	range_sprite.set_visible(true)

func _physics_process(_dt):
	position_range_sprite()

func position_range_sprite():
	if not range_sprite: return
	
	var waiting_is_over = not range_sprite.is_visible() and not quick_slash_still_disabled()
	if waiting_is_over:
		show_range_sprite()
	range_sprite.set_position(body.get_global_position())

func _on_Input_button_press():
	start_slash()

func _on_Input_button_release():
	finish_slash()

func _on_Input_move_vec(vec : Vector2):
	if not slashing_enabled: return
	if vec.length() <= 0.1: return
	
	emit_signal("aim")
	
	if GlobalDict.cfg.aim_helper:
		var vec_to_closest_target = snap_to_closest_target(vec)
		body.slowly_orient_towards_vec(vec_to_closest_target, 1.0)
		return
	
	var long_hold = get_time_held() > MAX_TIME_HELD
	if body.modules.status.rotate_incrementally():
		var rotate_dir = 1 if vec.x > 0 else -1
		var rotate_speed = ROTATE_SPEED
		if long_hold: rotate_speed *= 0.25
		
		# up/down keys are for faster rotating
		if vec.y > 0:
			rotate_dir = 1
			rotate_speed *= 2
		elif vec.y < 0:
			rotate_dir = -1
			rotate_speed *= 2
		
		body.rotate(rotate_dir*(2*PI)*rotate_speed)
	
	else:
		var factor = AIM_INTERP_FACTOR
		if long_hold: factor *= 0.25
		body.slowly_orient_towards_vec(vec, factor)

func snap_to_closest_target(aim_vec):
	var targets = mode.get_targets()
	if targets.size() <= 0: return aim_vec
	
	var pos = body.get_global_position()
	var best_dot = -INF
	var best_target
	for t in targets:
		var vec_to = (t.get_global_position() - pos).normalized()
		var dot = vec_to.dot(aim_vec)
		if dot < best_dot: continue
		
		best_dot = dot
		best_target = t
	
	# TO DO: Aim a bit _ahead_ of the others?
	var final_vec_to = (best_target.get_global_position() - pos).normalized()
	return final_vec_to

func start_slash():
	if body.modules.knives.has_no_knives(): return
	
	GlobalAudio.play_dynamic_sound(body, "windup_throw")
	
	slash_start_time = OS.get_ticks_msec()
	slashing_enabled = true

func finish_slash():
	if not slashing_enabled: return
	
	execute_slash()
	slashing_enabled = false

func execute_slash():
	determine_slash_range()
	
	GlobalAudio.play_dynamic_sound(body, "throw")

	if get_time_held() < THROW_TIME_THRESHOLD:
		execute_quick_slash()
	else:
		execute_thrown_slash()

func quick_slash_still_disabled():
	return (OS.get_ticks_msec() - last_quick_slash_time) < QUICK_SLASH_COOLDOWN_DURATION

func execute_quick_slash():
	if quick_slash_still_disabled(): return
	
	var start = body.get_global_position()
	var vec = body.modules.knives.get_first_knife_vec()
	
	body.modules.statistics.record("quick_stabs", 1)
	body.modules.statistics.record("knives_used", 1)
	
	if not vec:
		# print the "NO KNIVES" feedback
		return
	
	hide_range_sprite()
	
	# move ourselves _away_ from the quick slash, slightly randomized
	var rand_vec = -vec.rotated((randf()-0.5)*0.25*PI)
	body.modules.knockback.apply(rand_vec * slicer.SLICE_EXPLODE_FORCE)
	
	last_quick_slash_time = OS.get_ticks_msec()
	
	var first_knife = body.modules.knives.knives_held[0]
	
	animate_quick_slash(first_knife, vec*slash_range)
	particles.create_slash(first_knife.get_node("Projectile").get_knife_bottom_pos(), vec)
	body.modules.knives.move_first_knife_to_back()
	
	var end = start + vec * slash_range
	
	# first check if a body is there
	var res = shoot_raycast(start, end)
	if not res: return
	
	# if there is, extend the line to make sure we get a clean slice through
	end += vec * slash_range * 2
	
	# @params start, end, exclude, include
	slicer.slice_bodies_hitting_line(start, end, [body], [res.collider])
	
	emit_signal("quick_slash")
	
func animate_quick_slash(knife, vec_with_range):
	var start_pos = knife.get_position()
	var extended_pos = start_pos + vec_with_range.rotated(-body.rotation)
	var duration = 0.2
	
	body.modules.tween.interpolate_property(knife, "position",
		start_pos, extended_pos, duration,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	
	body.modules.tween.interpolate_property(knife, "position",
		extended_pos, start_pos, duration,
		Tween.TRANS_CUBIC, Tween.EASE_OUT,
		duration)
	
	body.modules.tween.start()

func shoot_raycast(start, end):
	var space_state = get_world_2d().direct_space_state 

	var exclude = [body]
	var collision_layer = 1 + 2 + 4 + 8
	
	return space_state.intersect_ray(start, end, exclude, collision_layer)

func execute_thrown_slash():
	body.modules.statistics.record("long_throws", 1)
	body.modules.statistics.record("knives_used", 1)
	
	body.modules.knives.throw_first_knife()
	emit_signal("thrown_slash")

func get_slash_range():
	return slash_range

func determine_slash_range():
	slash_range = clamp(range_multiplier * DEFAULT_SLASH_RANGE, SLASH_RANGE_BOUNDS.min, SLASH_RANGE_BOUNDS.max)
	
	var sprite_size : float = 256.0
	var new_scale = Vector2(1,1) * (slash_range / (0.5*sprite_size))
	
	if range_sprite:
		range_sprite.set_scale(new_scale)
	
	emit_signal("slash_range_changed", new_scale)

func change_range_multiplier(val):
	range_multiplier = clamp(range_multiplier * val, 0.2, 3.0)
	determine_slash_range()

func get_throw_strength(use_full_strength : bool = false):
	if use_full_strength: 
		return strength_multiplier * BASE_THROW_STRENGTH
	
	var strength = strength_multiplier * (get_time_held() / MAX_TIME_HELD) * BASE_THROW_STRENGTH
	return clamp(strength, THROW_STRENGTH_BOUNDS.min, THROW_STRENGTH_BOUNDS.max)

func change_throw_multiplier(val):
	strength_multiplier = clamp(strength_multiplier * val, 0.2, 3.0)

func get_curve_strength():
	var linear_val = clamp(strength_multiplier * BASE_THROW_STRENGTH, THROW_STRENGTH_BOUNDS.min, THROW_STRENGTH_BOUNDS.max)
	return 0.016*linear_val

func get_time_held():
	return (OS.get_ticks_msec() - slash_start_time)

func in_long_throw_mode():
	return get_time_held() > THROW_TIME_THRESHOLD

func pos_within_range(pos):
	var dist = (pos - body.get_global_position()).length()
	return dist <= slash_range

func held_too_long():
	return get_time_held() > MAX_TIME_HELD
