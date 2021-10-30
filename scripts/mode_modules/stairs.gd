extends Area2D

export var other_stairs : Vector2
export var detect_throwables : bool = false

func _ready():
	if detect_throwables:
		collision_layer += 32
		collision_mask += 32

func _on_Stairs_body_entered(body):
	if body.is_in_group("Throwables"):
		if not detect_throwables: return
		if not body.modules.status.react_to_areas(): return
	
	if not body.is_in_group("Players"): return
	if not body.modules.teleporter.forced_allowed(): return
	
	body.modules.teleporter.teleport(other_stairs)

func _on_Stairs_body_exited(body):
	body.modules.teleporter.reset_teleport()
