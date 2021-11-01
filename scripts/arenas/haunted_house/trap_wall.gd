extends Node2D

export var index : int = -1

onready var tex_progress = $TextureProgress
var lights = []

func _ready():
	for child in get_children():
		if child is Light2D:
			lights.append(child)

func activate():
	for light in lights:
		light.set_visible(true)

func update_progress(val):
	tex_progress.set_value(val)

func deactivate():
	tex_progress.set_value(0)
	
	for light in lights:
		light.set_visible(false)
