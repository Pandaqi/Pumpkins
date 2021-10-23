extends Node

# NOTE "owner" is a registered word with Godot, so use something else
var my_owner = null 

onready var body = get_parent()
onready var anim_player = get_node("../AnimationPlayer")
onready var sprite = get_node("../Sprite")

signal owner_changed(num)

func set_owner(o):
	my_owner = o
	
	var num = my_owner.modules.status.player_num
	sprite.set_frame(num)
	anim_player.stop()
	emit_signal("owner_changed", num)

func get_owner():
	return my_owner

func has_none():
	return (my_owner == null)

func remove():
	my_owner = null
	sprite.set_frame(8)
	anim_player.play("Highlight")
	emit_signal("owner_changed", -1)

func get_owner_rotation():
	if has_none(): return 0
	return my_owner.rotation
