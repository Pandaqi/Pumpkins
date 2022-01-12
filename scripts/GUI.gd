extends CanvasLayer

onready var tween = $Tween
onready var game_state = get_node("../GameState")

func tween_appearance(obj, use_delay = true):
	var old_scale = Vector2(0,0)
	var target_scale = Vector2(1,1)
	
	var duration = 0.3 + randf()*0.4
	var delay = randf()*1.25
	if not use_delay:
		delay = 0
	
	tween.interpolate_property(obj, "scale", 
		old_scale, target_scale, duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT, 
		delay)
	
	tween.start()
