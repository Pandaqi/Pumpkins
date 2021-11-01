extends Area2D

export var option : int = -1
export var multiframe : bool = false

onready var voter = get_parent()
var disabled : bool = false

func _ready():
	if multiframe:
		$Sprite.set_frame(option)

func disable():
	disabled = true

func enable():
	disabled = false

func _on_DirUp_body_entered(body):
	if disabled: return
	if not body.is_in_group("Players"): return
	if not body.modules.status.is_dead: return
	
	voter.cast_vote(self)
