extends PhysicsBody2D

var modules = {}

export var color : Color
export var override_color : bool = false

export var create_collectible_parts : bool = false

func _ready():
	register_modules()
	
	if modules.has('drawer') and override_color:
		modules.drawer.color = color

func register_modules():
	for child in get_children():
		if not is_instance_valid(child): continue
		var key = child.name.to_lower()
		modules[key] = child
