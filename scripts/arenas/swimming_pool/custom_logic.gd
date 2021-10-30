extends Node2D

const MAX_ITEMS : int = 4
const TIMER_BOUNDS = { 'min': 3, 'max': 10 }

var is_day : bool = true
export var night_color : Color

var lights = []
onready var canvas_mod = $CanvasModulate
onready var tween = $Tween

var water_lines : Array

onready var item_timer = $ItemTimer
var item_scenes = [
	preload("res://scenes/arenas/swimming_pool/swimming_ring.tscn"),
	preload("res://scenes/arenas/swimming_pool/swimming_pole.tscn"),
	preload("res://scenes/arenas/swimming_pool/crocodile.tscn")
]

onready var map = get_node("/root/Main/Map")

func activate():
	is_day = false
	
	for child in get_children():
		if child is Light2D:
			lights.append(child)
	
	water_lines = get_tree().get_nodes_in_group("WaterLines")
	
	_on_Timer_timeout()
	_on_ItemTimer_timeout()

func on_player_death(_p) -> Dictionary:
	return {}

func _on_Timer_timeout():
	change_mode()

func change_mode():
	is_day = not is_day
	
	#var lights_disabled = (not GlobalDict.cfg.light_effects)
	
	# brighten the lights?
	var delay = 0.0
	var delay_step = 0.2
	
	var start_scale = 1
	var end_scale = 2
	
	var start_energy = 0.45
	var end_energy = 1.0
	
	if is_day:
		var temp = end_scale
		end_scale = start_scale
		start_scale = temp
		
		temp = end_energy
		end_energy = start_energy
		start_energy = temp
	
	for light in lights:
		tween.interpolate_property(light, "texture_scale",
			start_scale, end_scale, 1.0,
			Tween.TRANS_ELASTIC, Tween.EASE_OUT,
			delay)
		
		tween.interpolate_property(light, "energy",
			start_energy, end_energy, 1.0,
			Tween.TRANS_ELASTIC, Tween.EASE_OUT,
			delay)
		
		delay += delay_step
	
	# don't need to modulate if no lights active
	var color = night_color
	if is_day: color = Color(1,1,1)
	
	if is_instance_valid(canvas_mod):
		tween.interpolate_property(canvas_mod, "color",
			canvas_mod.color, color, 1.0,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	# water line doesn't follow normal lights, do so manually
	var start_mod = Color(1,1,1,1)
	var end_mod = Color(0.6, 0.6, 0.6, 1.0)
	
	if is_day:
		var temp = end_mod
		end_mod = start_mod
		start_mod = temp
	
	for l in water_lines:
		tween.interpolate_property(l, "modulate",
			start_mod, end_mod, 1.0,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func _on_ItemTimer_timeout():
	item_timer.wait_time = rand_range(TIMER_BOUNDS.min, TIMER_BOUNDS.max)
	item_timer.start()
	
	var num_items = get_tree().get_nodes_in_group("ModeItems").size()
	if num_items >= MAX_ITEMS: return
	
	lights.shuffle()
	var rand_position = lights[0].global_position
	
	item_scenes.shuffle()
	var rand_item = item_scenes[0].instance()
	
	# DEBUGGING:
	rand_item = item_scenes[2].instance()
	
	rand_item.set_position(rand_position)
	map.entities.add_child(rand_item)
	
	tween.interpolate_property(rand_item, "scale", 
		Vector2.ZERO, Vector2(1,1), 0.66,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
