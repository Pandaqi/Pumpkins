extends Light2D

const BASE_PLAYBACK_SPEED = 0.8

onready var anim_player = $AnimationPlayer

func restart():
	anim_player.playback_speed = BASE_PLAYBACK_SPEED + (randf()-0.5)*0.15
