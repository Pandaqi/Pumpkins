extends Node2D

const REGROW_DURATION : int = 15
const MAX_REGROWS : int = 6

onready var body = get_parent()
onready var regrow_timer = $RegrowTimer
onready var tween = $Tween

var player_num = -1
var num_regrows : int = 0

func delete():
	if num_regrows >= MAX_REGROWS:
		body.queue_free()
	
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_visible(false)

	regrow_timer.wait_time = REGROW_DURATION + randf() * 5
	regrow_timer.start()
	
	body.modules.navigation.remove()

func regrow():
	body.collision_layer = 1
	body.collision_mask = 1
	
	body.set_visible(true)
	body.set_scale(Vector2.ZERO)
	
	tween.interpolate_property(body, "scale",
		Vector2.ZERO, Vector2(1,1), 0.5, 
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	num_regrows += 1
	
	body.modules.navigation.add()

func _on_RegrowTimer_timeout():
	regrow()
