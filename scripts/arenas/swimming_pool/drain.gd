extends Area2D

const DELETE_RANGE : float = 20.0
const STRENGTH : float = 2.0

var max_radius : float

onready var particles = get_node("/root/Main/Particles")

func _ready():
	max_radius = $CollisionShape2D.shape.radius

func _physics_process(dt):
	for b in get_overlapping_bodies():
		attract(b, dt)

func attract(b, dt):
	if not b.is_in_group("Throwables"): return
	if not b.modules.status.react_to_areas(): return
	
	var vec = (b.global_position - global_position)
	var factor = 1.0 - vec.length() / max_radius
	
	b.modules.mover.rotate_velocity_to(-vec, factor * STRENGTH * dt)
	
	if vec.length() <= DELETE_RANGE:
		particles.general_feedback(b.global_position, "Destroyed!")
		b.modules.status.delete()
