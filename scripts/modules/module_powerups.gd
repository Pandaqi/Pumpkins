extends Node

const POWERUP_DURATION : float = 10.0 # in seconds

const GROWTH_FACTOR : float = 0.2

var temporary = []
onready var body = get_parent()
onready var map = get_node("/root/Main/Map")

var powerup_fb_scene = preload("res://scenes/powerup_feedback.tscn")

func grab(type):
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

func show_feedback(type):
	var fb = powerup_fb_scene.instance()
	fb.set_type(type)
	fb.set_player(body)
	map.overlay.add_child(fb)

func _physics_process(_dt):
	handle_temporary_effects()

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
