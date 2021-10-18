extends Node2D

var is_hungry : bool = false
onready var body = get_parent()

func _on_Area2D_body_entered(other_body):
	print("SOMETHING ENTERED")
	
	if not other_body.is_in_group("Parts"): return
	if not is_hungry: return
	
	other_body.queue_free()
	body.modules.grower.grow(0.1)

func _on_Area2D_body_exited(other_body):
	pass # Replace with function body.
