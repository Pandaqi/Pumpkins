extends Node2D

var is_hungry : bool = false
onready var body = get_parent()
onready var main_node = get_node("/root/Main")

var num_collected : int = 0

var multiplier : int = 1
var collection_disabled : bool = false
var magnet_enabled : bool = false

func collect(dc):
	num_collected += dc
	
	main_node.player_progression(body.modules.status.player_num)

func disable_collection():
	collection_disabled = true

func enable_collection():
	collection_disabled = false
	for b in $Area2D.get_overlapping_bodies():
		_on_Area2D_body_entered(b)

func enable_magnet():
	magnet_enabled = true
	
	# TO DO: Create actual magnet area, actually listen to it and do something with it (if this is enabled)

func disable_magnet():
	magnet_enabled = false

func _on_Area2D_body_entered(other_body):
	print("SOMETHING ENTERED")
	
	if collection_disabled: return
	
	if not other_body.is_in_group("Parts"): return
	if not is_hungry: return
	
	other_body.queue_free()
	body.modules.grower.grow(0.1)
	
	collect(1 * multiplier)
