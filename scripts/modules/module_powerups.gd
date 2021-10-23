extends Node2D

const MAX_POWERUPS : int = 5
const POWERUP_DURATION : float = 10.0 # in seconds

const GROWTH_FACTOR : float = 0.2

var powerup_icons = []
var temporary = []

onready var body = get_parent()
onready var map = get_node("/root/Main/Map")
onready var particles = get_node("/root/Main/Particles")

var powerup_fb_scene = preload("res://scenes/powerup_feedback.tscn")
var powerup_icon_scene = preload("res://scenes/powerup_icon.tscn")

var disabled : bool = false

var repel_knives : bool = false
var auto_unwrap : bool = false

func _ready():
	for i in range(MAX_POWERUPS):
		var ic = powerup_icon_scene.instance()
		powerup_icons.append(ic)
		$Container.add_child(ic)

func disable():
	disabled = true

func grab(obj, type):
	if disabled: return
	if temporary.size() >= MAX_POWERUPS: 
		print("AT MAXIMUM POWERUPS")
		return
	
	GlobalAudio.play_dynamic_sound(body, "collect")
	particles.create_explosion_particles(obj.global_position)
	
	show_feedback(type)
	activate_effect(type)
	
	if GlobalDict.powerups[type].has("temporary"):
		remove_powerup_if_already_exists(type)
		temporary.append({ 'type': type, 'time': OS.get_ticks_msec() })

func remove_powerup_if_already_exists(type : String):
	for obj in temporary:
		if obj.type != type: continue
		temporary.erase(obj)
		return

func show_feedback(type, removal = false):
	var fb = powerup_fb_scene.instance()
	fb.set_type(type)
	fb.set_player(body)
	map.overlay.add_child(fb)
	
	if removal:
		fb.make_removal()

func _physics_process(_dt):
	show_temporary_effects_ui()
	
	if disabled: return
	
	handle_temporary_effects()

func show_temporary_effects_ui():
	var rot_step = 0.1*PI
	var cur_rot = -0.5*PI
	var radius = body.modules.slasher.get_slash_range()*0.9 # to account for white-space margin in that sprite
	
	for ic in powerup_icons:
		ic.set_visible(false)
		
		var pos = Vector2(cos(cur_rot), sin(cur_rot))*radius
		ic.set_position(pos)
		cur_rot += rot_step
	
	$Container.set_rotation(-body.rotation)
	
	for i in range(temporary.size()):
		var type = temporary[i].type
		var frame = GlobalDict.powerups[type].frame
		var icon = powerup_icons[i]
		
		icon.get_node("Sprite").set_frame(frame)
		icon.set_visible(true)

func handle_temporary_effects():
	if temporary.size() <= 0: return
	
	var cur_time = OS.get_ticks_msec()
	for i in range(temporary.size()-1,-1,-1):
		var obj = temporary[i]
		var time_diff = (cur_time - obj.time) / 1000.0
		
		if GlobalDict.powerups[obj.type].has("needs_process"):
			handle_temporary_effect(obj)
		
		if time_diff > POWERUP_DURATION:
			deactivate_effect(obj.type)
			temporary.remove(i)

func handle_temporary_effect(obj):
	pass

func activate_effect(type):
	match type:
		"grow":
			body.modules.grower.grow(GROWTH_FACTOR)
		
		"shrink":
			body.modules.grower.shrink(GROWTH_FACTOR)
		
		"morph":
			body.modules.shaper.morph_to_random_shape()
		
		"ghost":
			body.modules.status.make_ghost()
		
		"hungry":
			body.modules.collector.is_hungry = true
		
		"grow_range":
			body.modules.slasher.change_range_multiplier(1.5)
		
		"shrink_range":
			body.modules.slasher.change_range_multiplier(0.5)
		
		"extra_knife":
			body.modules.knives.create_new_knife()
		
		"lose_knife":
			body.modules.knives.lose_random_knife()
		
		"boomerang":
			body.modules.knives.make_boomerang()
		
		"curved":
			body.modules.knives.use_curve = true
		
		"faster_throw":
			body.modules.slasher.change_throw_multiplier(1.5)
		
		"slower_throw":
			body.modules.slasher.change_throw_multiplier(0.5)
		
		"faster_move":
			body.modules.mover.change_speed_multiplier(1.5)
		
		"slower_move":
			body.modules.mover.change_speed_multiplier(0.5)
		
		"reversed_controls":
			body.modules.mover.reversed = true
		
		"ice":
			body.modules.mover.ice = true
		
		"magnet":
			body.modules.collector.enable_magnet()
		
		"duplicator":
			body.modules.collector.multiplier = 1
		
		"clueless":
			body.modules.collector.disable_collection()
		
		"repel_knives":
			repel_knives = true
		
		"auto_unwrap":
			auto_unwrap = true

func deactivate_effect(type):
	match type:
		"ghost":
			body.modules.status.undo_ghost()
		
		"hungry":
			body.modules.collector.is_hungry = false
		
		"boomerang":
			body.modules.knives.undo_boomerang()
		
		"curved":
			body.modules.knives.use_curve = false
		
		"reversed_controls":
			body.modules.mover.reversed = false
		
		"ice":
			body.modules.mover.ice = false
		
		"magnet":
			body.modules.collector.disable_magnet()
		
		"duplicator":
			body.modules.collector.multiplier = 2
		
		"clueless":
			body.modules.collector.enable_collection()
		
		"repel_knives":
			repel_knives = false
		
		"auto_unwrap":
			auto_unwrap = false
	
	GlobalAudio.play_dynamic_sound(body, "lose")
	show_feedback(type, true)
