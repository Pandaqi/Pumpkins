extends StaticBody2D

onready var throwable_deleter = $ThrowableDeleter
onready var gate_sprite = $Sprite

func deactivate(tween):
	throwable_deleter.deactivate()
	
	gate_sprite.set_scale(Vector2.ZERO)
	tween.interpolate_property(gate_sprite, "scale",
		Vector2.ZERO, Vector2(1,1), 0.5,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

func activate(tween):
	throwable_deleter.activate()

	gate_sprite.set_scale(Vector2(1,1))
	tween.interpolate_property(gate_sprite, "scale",
		Vector2(1,1), Vector2.ZERO, 0.5,
		Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.start()
