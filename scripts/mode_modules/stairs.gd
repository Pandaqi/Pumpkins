extends Area2D

export var other_stairs : Vector2

func _on_Stairs_body_entered(body):
	print("TRYING TELEPORTo")
	
	if not body.is_in_group("Players"): return
	if not body.forced_teleport_allowed: return
	
	body.plan_teleport(other_stairs)
	body.forced_teleport_allowed = false
	
	print("TELEPORTO")

# NOTE: we use "set_deferred" to ensure this triggers AFTER the "body_enter" signal on the other teleport
# (as this variable will now only reset at the END of this frame)
# Neat trick, works well, should use it more often.
func _on_Stairs_body_exited(body):
	body.set_deferred("forced_teleport_allowed", true)
