extends Node2D

var my_player = null
var throwable_tex = preload("res://assets/throwable_icons.png")
var is_throwable : bool = false

func _ready():
	$Sprite/RemovalIcon.set_visible(false)

func make_removal():
	$Sprite/RemovalIcon.set_visible(true)

func make_throwable():
	$Sprite.texture = throwable_tex
	is_throwable = true

func set_type(type):
	var frame = -1
	if is_throwable:
		frame = GlobalDict.throwables[type].frame
	else:
		frame = GlobalDict.powerups[type].frame
	
	$Sprite.set_frame(frame)

func set_player(p):
	my_player = p
	position_above_player()

func _physics_process(_dt):
	position_above_player()

func position_above_player():
	set_position(my_player.get_global_position())
