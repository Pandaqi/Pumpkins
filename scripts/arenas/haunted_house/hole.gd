extends Area2D

onready var tween = $Tween

func _ready():
	set_scale(Vector2.ZERO)
	tween.interpolate_property(self, "scale",
		Vector2(1,1)*0.0, Vector2(1,1)*2.0, 4.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func _on_Hole_body_entered(body):
	body.modules.mover.force_disable()

func on_delete():
	for b in get_overlapping_bodies():
		b.modules.mover.force_enable()
