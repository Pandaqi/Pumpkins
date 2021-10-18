extends Node

const POWERUP_DURATION : float = 10.0 # in seconds

const GROWTH_FACTOR : float = 0.2

var temporary = []
onready var body = get_parent()

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

# TO DO: Show icon above our heads or something
func show_feedback(type):
	pass

func _physics_process(dt):
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
			pass
		
		"ghost":
			body.modules.status.make_ghost()
		
		"hungry":
			body.modules.collector.is_hungry = true
			print("MADE HUNGRY")
		
		"grow_range":
			body.modules.slasher.change_range_multiplier(1.5)
		
		"shrink_range":
			body.modules.slasher.change_range_multiplier(0.5)
		
		"extra_knife":
			body.modules.knives.create_new_knife()
		
		"lose_knife":
			body.modules.knives.lose_random_knife()
		
		"boomerang":
			body.modules.knives.are_boomerang = true

func deactivate_effect(type):
	match type:
		"ghost":
			body.modules.status.undo_ghost()
		
		"hungry":
			body.modules.collector.is_hungry = false
		
		"boomerang":
			body.modules.knives.are_boomerang = false
