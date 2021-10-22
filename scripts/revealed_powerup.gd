extends Node2D

var type : String = ""
var still_inside : bool = true

onready var sprite = $Sprite

func reveal(pos : Vector2):
	set_position(pos)
	set_rotation(randf()*2*PI)
	set_visible(true)
	still_inside = false

func unreveal():
	set_visible(false)

func set_type(tp):
	type = tp
	
	var frame = GlobalDict.powerups[type].frame
	sprite.set_frame(frame)

func _on_Area2D_body_entered(body):
	if still_inside:
		if not GlobalDict.cfg.auto_pickup_powerups and not body.modules.powerups.auto_unwrap:
			return
	
	body.modules.statistics.record("powerups_grabbed", 1)
	body.modules.powerups.grab(type)
	self.queue_free()
	
	if still_inside:
		get_parent().queue_free()
