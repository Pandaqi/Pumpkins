extends Node2D

onready var respawn_timer = $RespawnTimer
onready var anim_player = $AnimationPlayer

onready var particles = get_node("/root/Main/Particles")

onready var body = get_parent()

func respawn():
	body.set_rotation(0)
	
	body.modules.knives.destroy_knives()
	body.modules.shaper.destroy()
	body.modules.shaper.create_from_shape_list(body.modules.status.starting_shape)
	
	var old_position = body.global_position
	var new_position = body.modules.status.starting_position
	body.modules.teleporter.teleport(new_position)
	
	particles.general_feedback(old_position, "Dead!")
	particles.general_feedback(new_position, "Respawn!")
	
	body.modules.status.make_ghost()
	respawn_timer.start()
	anim_player.play("RespawnFlicker")

func _on_RespawnTimer_timeout():
	body.modules.status.undo_ghost()
	anim_player.stop()
