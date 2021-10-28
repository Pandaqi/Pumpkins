extends Node2D

onready var area = $Area2D
onready var col_shape = $Area2D/CollisionShape2D
onready var body = get_parent()

func _ready():
	col_shape.shape = col_shape.shape.duplicate(true)

func _on_Shaper_shape_updated():
	col_shape.shape.radius = 1.5 * body.modules.shaper.approximate_radius()

func _on_Area2D_body_entered(other_body):
	if not other_body.is_in_group("Dumplings"): return
	if other_body.modules.status.being_held: return
	
	body.modules.grower.grow(0.05, true)
	other_body.queue_free()
