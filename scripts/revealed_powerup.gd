extends Node2D

var type : String = ""
var still_inside : bool = true
var is_throwable : bool = false

onready var sprite = $Sprite
onready var powerups = get_node("/root/Main/Powerups")
onready var throwables = get_node("/root/Main/Throwables")

func reveal(pos : Vector2):
	set_position(pos)
	set_rotation(randf()*2*PI)
	set_visible(true)
	still_inside = false
	
	powerups.tween_revealed_powerup(self)
	
	if is_throwable:
		throwables.change_count(+1)

func unreveal():
	set_visible(false)

func get_data():
	if is_throwable:
		return GlobalDict.throwables[type]
	else:
		return GlobalDict.powerups[type]

func set_type(tp):
	type = tp
	
	var frame = get_data().frame
	sprite.set_frame(frame)

func _on_Area2D_body_entered(body):
	if not body.is_in_group("Players"): return
	
	if still_inside:
		if not GlobalDict.cfg.auto_pickup_powerups and not body.modules.powerups.auto_unwrap:
			return
	
	if is_throwable:
		body.modules.statistics.record("throwables_grabbed", 1)
	else:
		body.modules.statistics.record("powerups_grabbed", 1)
	
	body.modules.powerups.grab(self, type, is_throwable)
	self.queue_free()
	
	if still_inside:
		get_parent().queue_free()
