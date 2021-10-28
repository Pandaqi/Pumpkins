extends Node2D

var modules = {}
var forced_teleport_allowed = true

func _ready():
	register_modules()

func register_modules():
	for child in get_children():
		if not is_instance_valid(child): continue
		var key = child.name.to_lower()
		modules[key] = child

func teleport_to(pos):
	set_position(pos)
