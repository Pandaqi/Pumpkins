extends Area2D

export var option : int = -1

onready var voter = get_parent()

func _on_DirUp_body_entered(body):
	if not body.is_in_group("Players"): return
	if not body.modules.status.is_dead: return
	
	voter.cast_vote(self)
