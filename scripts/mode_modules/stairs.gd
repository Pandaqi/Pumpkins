extends Area2D

export var other_stairs : Vector2
export var detect_throwables : bool = false

func _ready():
	if detect_throwables:
		collision_layer += 32
		collision_mask += 32

func _on_Stairs_body_entered(body):
	if detect_throwables and body.is_in_group("Throwables"):
		if body.forced_teleport_allowed and not body.modules.status.being_held: 
			body.teleport_to(other_stairs)
			body.forced_teleport_allowed = false
		return
	
	if not body.is_in_group("Players"): return
	if not body.forced_teleport_allowed: return
	if body.modules.status.teleport_timer.time_left > 0: return
	
	body.plan_teleport(other_stairs)
	body.forced_teleport_allowed = false
	body.modules.status.teleport_timer.start()

# NOTE: we use "set_deferred" to ensure this triggers AFTER the "body_enter" signal on the other teleport
# (as this variable will now only reset at the END of this frame)
# Neat trick, works well, should use it more often.
func _on_Stairs_body_exited(body):
	body.set_deferred("forced_teleport_allowed", true)
