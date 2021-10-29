extends Area2D

onready var particles = get_node("/root/Main/Particles")
export var exclude_types : Array = []

var active : bool = false

func _ready():
	collision_mask = 32
	collision_layer = 32

func deactivate():
	active = false

func activate():
	active = true
	
	for b in get_overlapping_bodies():
		_on_Area2D_body_entered(b)

func _on_Area2D_body_entered(body):
	if not active: return
	
	if not body.is_in_group("Throwables"): return
	if body.modules.status.being_held: return
	if body.modules.status.type in exclude_types: return
	
	particles.general_feedback(body.global_position, "Destroyed!")
	body.queue_free()
