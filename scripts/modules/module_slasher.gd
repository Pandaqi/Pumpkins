extends Node2D

const THROW_TIME_THRESHOLD : float = 220.0 # milliseconds
const QUICK_SLASH_COOLDOWN_DURATION : float = 3000.0 # milliseconds

const ROTATE_SPEED : float = 0.75
const WATER_ROTATE_SPEED : float = 0.66*ROTATE_SPEED
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

const MAX_TIME_HELD : float = 1750.0 # holding longer than this changes nothing anymore
const MAX_SLOWDOWN_TIME : float = 5000.0 # during this period, your rotating speed keeps slowing down
const THROW_STRENGTH_BOUNDS = { 'min': 250, 'max': 2500 }
var strength_multiplier : float = 1.0
onready var throw_strength_sprite = $ThrowStrength

# seconds of being idle before it auto-throws your knife
const IDLE_PENALTY_INTERVAL : float = 15.0
const IDLE_REMINDER_THRESHOLD : float = 3.0

onready var idle_timer = $IdleHourglass/IdleTimer
onready var idle_hourglass = $IdleHourglass
onready var idle_hourglass_anim_player = $IdleHourglass/IdleHourglass/AnimationPlayer

var disabled : bool = false

signal slash_range_changed(new_scale)
signal quick_slash()
signal thrown_slash()
signal aim()

func _ready():
	remove_child(range_sprite)
	map.ground.add_child(range_sprite)
	determine_slash_range()
	
	if (not GlobalDict.cfg.show_guides) or (not GlobalDict.cfg.allow_quick_slash):
		range_sprite.queue_free()
		range_sprite = null
	
	remove_child(throw_strength_sprite)
	map.ground.add_child(throw_strength_sprite)
	
	throw_strength_sprite.material = throw_strength_sprite.material.duplicate(true)
	throw_strength_sprite.material.set_shader_param("ratio", 0.0)
	throw_strength_sprite.set_visible(false)

func disable():
	disabled = true
	
	throw_strength_sprite.set_visible(false)

func set_player_num(num):
	player_num = num
	
	if range_sprite:
		range_sprite.set_frame(num)

func hide_range_sprite():
	if not range_sprite: return
	range_sprite.set_visible(false)

func show_range_sprite():
	if not range_sprite: return
	range_sprite.set_visible(true)

func _physics_process(_dt):
	if disabled: return
	
	show_idle_hourglass()
	grow_strength_sprite()
	position_range_sprite()

func show_idle_hourglass():
	if not use_idle_timer(): return
	if idle_timer.time_left >= IDLE_REMINDER_THRESHOLD: return
	
	idle_hourglass.set_rotation(-body.rotation)
	idle_hourglass.set_visible(true)
	idle_hourglass_anim_player.play("IdleHourglass")

func position_range_sprite():
	if not range_sprite: return
	
	var waiting_is_over = not range_sprite.is_visible() and not quick_slash_still_disabled()
	if waiting_is_over:
		show_range_sprite()
	range_sprite.set_position(body.get_global_position())

func grow_strength_sprite():
	throw_strength_sprite.set_position(body.get_global_transform_with_canvas().origin)
	
	# NOTE: taking a square root (or more) means it _starts_ growing really quickly, but _slows down_ near 1.0
	# Which looks really smooth and I should probably use it more ... 
	var strength_ratio = clamp(pow(get_time_held() / MAX_TIME_HELD, 0.4), 0.0, 1.0)
	throw_strength_sprite.material.set_shader_param("ratio", strength_ratio)
	
	if throw_strength_sprite.is_visible():
		body.modules.knives.update_guide_material(strength_ratio)

func _on_Input_button_press():
	if disabled: return
	if body.modules.specialstatus.stun.is_stunned: 
		body.modules.particles.continuous_feedback("Stunned!")
		return
	
	start_slash()

func _on_Input_button_release():
	if disabled: return
	if body.modules.specialstatus.stun.is_stunned: 
		body.modules.particles.continuous_feedback("Stunned!")
		return
	
	finish_slash()

# TO DO: This only works because a move vector is sent EVERY FRAME, even if you're not inputting anything
# => not the cleanest way to do it
func _on_Input_move_vec(vec : Vector2, dt : float):
	if disabled: return
	if not slashing_enabled: return
	
	if not GlobalDict.cfg.use_control_scheme_with_joystick_aim and not body.modules.status.is_bot:
		vec = Vector2.RIGHT
	
	if body.modules.status.in_water:
		var rotate_dir = 1 if vec.x > 0 else -1
		var rotate_speed = WATER_ROTATE_SPEED
		body.rotate(rotate_dir*(2*PI)*rotate_speed*dt)
		return
	
	if vec.length() <= 0.1: return
	
	emit_signal("aim")
	
	var long_hold = get_time_held() > MAX_TIME_HELD
	var slowdown_factor = clamp(1.0 - get_time_held() / MAX_SLOWDOWN_TIME, 0.45, 1.0)
	if body.modules.status.rotate_incrementally():
		var rotate_dir = 1 if vec.x > 0 else -1
		var rotate_speed = ROTATE_SPEED
		if GlobalDict.cfg.slow_down_aiming_over_time: 
			rotate_speed *= slowdown_factor
		
		body.rotate(rotate_dir*(2*PI)*rotate_speed*dt)
	
	else:
		var factor = AIM_INTERP_FACTOR
		if long_hold: factor *= 0.25
		body.slowly_orient_towards_vec(vec, factor)
	
	if GlobalDict.cfg.aim_helper:
		var vec_to_closest_target = snap_to_closest_target(body.get_forward_vec())
		body.slowly_orient_towards_vec(vec_to_closest_target, 1.0)
		return

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
	throw_strength_sprite.set_visible(true)
	
	slash_start_time = OS.get_ticks_msec()
	slashing_enabled = true

func finish_slash():
	if not slashing_enabled: return
	
	execute_slash()
	throw_strength_sprite.set_visible(false)
	body.modules.knives.update_guide_material(0.0)
	slashing_enabled = false

func execute_slash():
	determine_slash_range()
	
	GlobalAudio.play_dynamic_sound(body, "throw")
	reset_idle_timer()
	
	var quick_slash : bool = GlobalDict.cfg.allow_quick_slash and (get_time_held() < THROW_TIME_THRESHOLD)

	if quick_slash:
		execute_quick_slash()
		return
	
	execute_thrown_slash()

func quick_slash_still_disabled():
	return (OS.get_ticks_msec() - last_quick_slash_time) < QUICK_SLASH_COOLDOWN_DURATION

func execute_quick_slash():
	if quick_slash_still_disabled(): return
	
	var start = body.get_global_position()
	var vec = body.modules.knives.get_first_knife_vec()
	
	body.modules.statistics.record("quick_stabs", 1)
	body.modules.statistics.record("knives_used", 1)
	
	if not vec: return
	
	hide_range_sprite()
	
	# move ourselves _away_ from the quick slash, slightly randomized
	var rand_vec = -vec.rotated((randf()-0.5)*0.25*PI)
	body.modules.knockback.apply(rand_vec * slicer.SLICE_EXPLODE_FORCE)
	
	last_quick_slash_time = OS.get_ticks_msec()
	
	var first_knife = body.modules.knives.knives_held[0]
	
	animate_quick_slash(first_knife, vec*slash_range)
	var pos = first_knife.modules.fakebody.get_bottom_pos()
	particles.create_slash(pos, vec)
	body.modules.knives.move_first_knife_to_back()
	
	var end = start + vec * slash_range
	
	# first check if a body is there
	var res = shoot_raycast(start, end)
	if not res: return
	
	# if there is, extend the line to make sure we get a clean slice through
	end += vec * slash_range * 2
	
	# @params start, end, exclude, include
	slicer.slice_bodies_hitting_line(start, end, [body], [res.collider], null)
	
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
	if use_full_strength:  return THROW_STRENGTH_BOUNDS.max
	
	var hold_ratio = clamp(get_time_held() / MAX_TIME_HELD, 0.1, 1.0)
	var strength = strength_multiplier * hold_ratio * (THROW_STRENGTH_BOUNDS.max - THROW_STRENGTH_BOUNDS.min) + THROW_STRENGTH_BOUNDS.min
	return strength

func change_throw_multiplier(val):
	strength_multiplier = clamp(strength_multiplier * val, 0.2, 3.0)

func get_curve_strength():
	return 0.016*get_throw_strength(true)

func get_time_held():
	return (OS.get_ticks_msec() - slash_start_time)

func in_long_throw_mode():
	if not GlobalDict.cfg.allow_quick_slash: return true
	return get_time_held() > THROW_TIME_THRESHOLD

func pos_within_range(pos):
	var dist = (pos - body.get_global_position()).length()
	return dist <= slash_range

func held_too_long():
	return get_time_held() > MAX_TIME_HELD

func reset_idle_timer():
	idle_hourglass.set_visible(false)
	idle_hourglass_anim_player.stop()
	
	idle_timer.stop()
	idle_timer.wait_time = IDLE_PENALTY_INTERVAL
	idle_timer.start()

# We've grabbed/thrown a knife and then not done something for X seconds
# The penalty? Automatically throw something
func _on_IdleTimer_timeout():
	reset_idle_timer()
	if not use_idle_timer(): return
	
	execute_thrown_slash()

func use_idle_timer():
	if not GlobalDict.cfg.auto_throw_if_idle: return false
	var no_first_knife = (not body.modules.knives.get_first_knife())
	if no_first_knife: return false
	return true

func self_slice(attacking_throwable = null):
	var center = body.global_position
	var rot = 2*PI*randf()
	var rand_vec = Vector2(cos(rot), sin(rot))
	var start = center + rand_vec * 400
	var end = center - rand_vec*400
	
	var result = slicer.slice_bodies_hitting_line(start, end, [], [body], null)
	
	# if we sliced something, create exceptions between us and whatever we sliced
	if attacking_throwable and result:
		attacking_throwable.modules.fakebody.add_collision_exception(body)
		for sliced_body in result:
			attacking_throwable.modules.fakebody.add_collision_exception(sliced_body)
