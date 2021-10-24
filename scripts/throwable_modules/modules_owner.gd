extends Node

# NOTE "owner" is a registered word with Godot, so use something else
var my_owner = null 
var mode : String = "auto"

onready var body = get_parent()
onready var anim_player = get_node("../AnimationPlayer")
onready var sprite = get_node("../Sprite")

signal owner_changed(num)

func set_mode(m):
	mode = m

func is_hostile():
	return (mode == "hostile")

func is_friendly():
	return (mode == "friendly")

func set_owner(o):
	if mode != "auto": return
	
	my_owner = o

	var num = my_owner.modules.status.player_num
	sprite.set_frame(body.modules.status.base_frame + num)
	anim_player.stop()
	emit_signal("owner_changed", num)

func get_owner():
	return my_owner

func is_body(other_body):
	return my_owner == other_body

func has_none():
	return (my_owner == null)

func remove():
	if mode != "auto": return
	
	my_owner = null
	sprite.set_frame(body.modules.status.base_frame + 8)
	anim_player.play("Highlight")
	emit_signal("owner_changed", -1)

func get_owner_rotation():
	if has_none(): return 0
	return my_owner.rotation

func get_vec_to():
	if has_none(): return Vector2.ZERO
	return (my_owner.global_position - body.global_position)
