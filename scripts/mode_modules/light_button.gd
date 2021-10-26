extends Node2D

export var room_num : int = 0

onready var map = get_node("/root/Main/Map")
onready var timer = $Timer

var ghosts_on_me = []

func on_throwable_hit(_throwable):
	lights_out()

func lights_out():
	var my_sprite = map.overlay.get_node("Overlay" + str(room_num))
	my_sprite.set_visible(true)
	timer.start()

func _on_Timer_timeout():
	lights_on()

func lights_on():
	var my_sprite = map.overlay.get_node("Overlay" + str(room_num))
	my_sprite.set_visible(false)

func _on_Area2D_body_entered(_body):
	var num_bodies = $Area2D.get_overlapping_bodies().size()
	var already_on = (timer.time_left <= 0)
	if num_bodies >= 2 and not already_on:
		lights_out()
