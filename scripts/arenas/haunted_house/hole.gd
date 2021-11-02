extends Area2D

func _on_Hole_body_entered(body):
	body.modules.mover.disable()
	body.modules.mover.force_move_override = true

func on_delete():
	for b in get_overlapping_areas():
		b.modules.mover.enable()
		b.modules.mover.force_move_override = false
