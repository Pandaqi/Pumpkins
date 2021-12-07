extends Node2D

onready var body = get_parent()

var original_size : float = 256.0
var ghost_scale : float = 0.25
var is_ghost : bool = false

onready var face = $Sprite/Face

func hide_completely():
	pass

func make_ghost():
	set_frame(body.modules.status.player_num + 8)
	
	if body.modules.status.is_dead:
		set_scale(Vector2(1,1)*ghost_scale)
		is_ghost = true

func set_frame(num):
	$Sprite.set_frame(num)

func _on_Shaper_shape_updated():
	if is_ghost: return
	
	var radius = 2*body.modules.shaper.approximate_radius()
	var new_scale = radius / original_size
	set_scale(Vector2(1,1)*new_scale)

func update_face():
	var frame = 0
	
	if body.modules.specialstatus.stun.is_stunned:
		frame = 1
	
	if body.modules.specialstatus.invincibility.is_invincible:
		frame = 2
	
	face.set_frame(frame)
