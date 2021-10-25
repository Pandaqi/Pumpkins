extends Node2D

const REGROW_DURATION : int = 10

onready var body = get_parent()
onready var regrow_timer = $RegrowTimer
onready var tween = $Tween

var player_num = -1

func delete():
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_visible(false)
	
	regrow_timer.wait_time = REGROW_DURATION + randf() * 5
	regrow_timer.start()

func regrow():
	body.collision_layer = 1
	body.collision_mask = 1
	
	body.set_visible(true)
	body.set_scale(Vector2.ZERO)
	
	tween.interpolate_property(body, "scale",
		Vector2.ZERO, Vector2(1,1), 0.5, 
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

func _on_RegrowTimer_timeout():
	regrow()
