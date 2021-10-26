extends Node2D

const INVINCIBILITY_DURATION : float = 4.0
const BLOW_AWAY_STRENGTH : float = 4000.0

onready var body = get_parent()
onready var timer = $Timer
onready var anim_player = $AnimationPlayer

func _on_Shaper_shape_updated():
	on_hit()

func on_hit():
	timer.wait_time = INVINCIBILITY_DURATION
	timer.start()
	
	anim_player.play("Invincible")
	
	for b in $Area2D.get_overlapping_bodies():
		if not b.is_in_group("Players"): return
		var away_vec = (b.global_position - body.global_position).normalized()
		b.modules.knockback.apply(away_vec * BLOW_AWAY_STRENGTH)
	
	body.remove_from_group("Sliceables")

func _on_Timer_timeout():
	body.add_to_group("Sliceables")
	
	anim_player.stop()
