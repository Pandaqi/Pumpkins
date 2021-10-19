extends Node

const THROW_TIME_THRESHOLD : float = 250.0

onready var body = get_parent()
onready var slicer = get_node("/root/Main/Slicer")
onready var map = get_node("/root/Main/Map")
var slashing_enabled : bool = false

var slash_start_time : float

const SLASH_RANGE_BOUNDS = { 'min': 100, 'max': 260 }
const DEFAULT_SLASH_RANGE = 200
var range_multiplier : float = 1.0
var slash_range : float
onready var range_sprite = $Sprite

const MAX_TIME_HELD : float = 800.0 # holding longer than this changing nothing anymore
const THROW_STRENGTH_BOUNDS = { 'min': 900, 'max': 2000 }
const BASE_THROW_STRENGTH : float = 1800.0
var strength_multiplier : float = 1.0

func _ready():
	remove_child(range_sprite)
	map.ground.add_child(range_sprite)
	determine_slash_range()

func _physics_process(_dt):
	range_sprite.set_position(body.get_global_position())

func _on_Input_button_press():
	start_slash()

func _on_Input_button_release():
	finish_slash()

func _on_Input_move_vec(vec : Vector2):
	if not slashing_enabled: return
	if vec.length() <= 0.1: return
	
	var factor = clamp(1.0 - (OS.get_ticks_msec() - slash_start_time)/(2*MAX_TIME_HELD), 0.02, 1.0)
	body.slowly_orient_towards_vec(vec, factor)

func start_slash():
	slash_start_time = OS.get_ticks_msec()
	slashing_enabled = true

func finish_slash():
	execute_slash()
	slashing_enabled = false

func execute_slash():
	determine_slash_range()
	
	var time_held = OS.get_ticks_msec() - slash_start_time
	if time_held < THROW_TIME_THRESHOLD:
		execute_quick_slash()
	else:
		execute_thrown_slash()

func execute_quick_slash():
	var start = body.get_global_position()
	var vec = body.modules.knives.get_first_knife_vec()
	if not vec:
		# print the "NO KNIVES" feedback
		return
	
	var end = start + vec * slash_range
	
	slicer.slice_bodies_hitting_line(start, end, [body])
	
	body.modules.knives.move_first_knife_to_back()

func execute_thrown_slash():
	body.modules.knives.throw_first_knife()

func determine_slash_range():
	slash_range = clamp(range_multiplier * DEFAULT_SLASH_RANGE, SLASH_RANGE_BOUNDS.min, SLASH_RANGE_BOUNDS.max)
	
	var sprite_size : float = 256.0
	var new_scale = Vector2(1,1) * (slash_range / (0.5*sprite_size))
	range_sprite.set_scale(new_scale)

func change_range_multiplier(val):
	range_multiplier = clamp(range_multiplier * val, 0.2, 3.0)
	determine_slash_range()

func get_throw_strength():
	var time_held = (OS.get_ticks_msec() - slash_start_time)
	var strength = strength_multiplier * (time_held / MAX_TIME_HELD) * BASE_THROW_STRENGTH
	return clamp(strength, THROW_STRENGTH_BOUNDS.min, THROW_STRENGTH_BOUNDS.max)

func change_throw_multiplier(val):
	strength_multiplier = clamp(strength_multiplier * val, 0.2, 3.0)

func get_curve_strength():
	var linear_val = clamp(strength_multiplier * BASE_THROW_STRENGTH, THROW_STRENGTH_BOUNDS.min, THROW_STRENGTH_BOUNDS.max)
	return 0.016*linear_val
