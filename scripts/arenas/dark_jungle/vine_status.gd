extends Node2D

export var REGROW_DURATION : int = 15
export var MAX_REGROWS : int = 6

onready var body = get_parent()
onready var regrow_timer = $RegrowTimer
onready var tween = $Tween

var player_num = -1
var num_regrows : int = 0

var occluder = null

func _ready():
	model_occluder_after_body()

func model_occluder_after_body():
	if not body.has_node("LightOccluder2D"): return
	
	occluder = body.get_node("LightOccluder2D")
	
	var shape = OccluderPolygon2D.new()
	shape.polygon = body.get_node("CollisionPolygon2D").polygon
	
	occluder.occluder = shape
	occluder.light_mask = 2
	
	print("MODELLING OCCLUDER AFTER BODY")

func delete():
	GlobalAudio.play_dynamic_sound(body, "vine")
	
	if num_regrows >= MAX_REGROWS:
		body.queue_free()
	
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_visible(false)

	regrow_timer.wait_time = REGROW_DURATION + randf() * 5
	regrow_timer.start()

	if occluder and is_instance_valid(occluder): occluder.set_visible(false)

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
	
	if occluder and is_instance_valid(occluder): occluder.set_visible(true)

func _on_RegrowTimer_timeout():
	regrow()
