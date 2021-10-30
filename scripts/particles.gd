extends Node

var slash_particle = preload("res://scenes/particles/slash_sprite.tscn")
var explosion_particle = preload("res://scenes/particles/explosion.tscn")
var collectible_particle = preload("res://scenes/particles/collectible.tscn")
var general_feedback_scene = preload("res://scenes/particles/general_feedback.tscn")

var map = null

func _ready():
	if has_node("../Map"):
		map = get_node("../Map")

func create_slash(pos, vec):
	var p = slash_particle.instance()
	p.set_position(pos)
	p.set_rotation(vec.angle())
	
	map.overlay.add_child(p)

func create_collectible_particle(pos, val):
	var p = collectible_particle.instance()
	p.set_position(pos)
	p.set_text(val)
	
	map.overlay.add_child(p)

func create_explosion_particles(pos):
	var p = explosion_particle.instance()
	p.set_position(pos)
	
	map.overlay.add_child(p)

func general_feedback(pos, val, parent = null):
	var fb = general_feedback_scene.instance()
	fb.set_position(pos)
	
	fb.set_text(val)
	
	if not parent:
		map.overlay.add_child(fb)
	else:
		parent.add_child(fb)
