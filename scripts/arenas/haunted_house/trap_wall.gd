extends Node2D

export var index : int = -1

onready var tex_progress = $TextureProgress
var lights = []

var bodies_created = []

onready var functionality = $Functionality

func _ready():
	for child in get_children():
		if child is Light2D:
			lights.append(child)

func activate():
	for light in lights:
		light.set_visible(true)
	
	functionality.activate()

func update_progress(val):
	tex_progress.set_value(val)

func deactivate():
	tex_progress.set_value(0)
	
	for light in lights:
		light.set_visible(false)
	
	functionality.deactivate()
	
	for b in bodies_created:
		var has_been_picked_up = (b.is_in_group("Throwables") and b.modules.status.being_held)
		if has_been_picked_up: continue
		
		var has_custom_delete_behavior = b.has_method("on_delete")
		if has_custom_delete_behavior: b.on_delete()
		
		b.queue_free()
	
	bodies_created = []
