extends Node2D

const RANDOM_LIGHTSOFF_INTERVAL = 25

onready var map = get_node("/root/Main/Map")
onready var auto_lightsoff_timer = $AutoLightsoffTimer

func activate():
	hide_black_overlays()
	
	auto_lightsoff_timer.wait_time = RANDOM_LIGHTSOFF_INTERVAL
	auto_lightsoff_timer.start()

func hide_black_overlays():
	for i in range(7):
		map.overlay.get_node("Overlay" + str(i+1)).set_visible(false)

func on_player_death(_p) -> Dictionary:
	return {}

func _on_AutoLightsoffTimer_timeout():
	var lights = get_tree().get_nodes_in_group("LightButtons")
	lights.shuffle()
	lights[0].lights_out()
