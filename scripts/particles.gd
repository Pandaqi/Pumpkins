extends Node

var slash_particle = preload("res://scenes/particles/slash_sprite.tscn")
var team_reminder # = preload("res://scenes/particles/team_reminder.tscn")

onready var map = get_node("../Map")

func create_slash(pos, vec):
	var p = slash_particle.instance()
	p.set_position(pos)
	p.set_rotation(vec.angle())
	
	map.overlay.add_child(p)

func show_team_reminder(body, num):
	return
	
	var t = team_reminder.instance()
	t.get_node("Sprite").set_frame(num)
	body.add_child(t)
