extends Node2D

var my_player = null

func _ready():
	$Sprite/RemovalIcon.set_visible(false)

func make_removal():
	$Sprite/RemovalIcon.set_visible(true)

func set_type(type):
	$Sprite.set_frame(GlobalDict.powerups[type].frame)

func set_player(p):
	my_player = p
	position_above_player()

func _physics_process(_dt):
	position_above_player()

func position_above_player():
	set_position(my_player.get_global_position())
