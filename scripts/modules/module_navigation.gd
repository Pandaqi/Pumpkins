extends Node2D

var nav_data = {}
var empty_outline = []
onready var nav = get_node("/root/Main/Navigation")

func set_data(d):
	nav_data = d

func add():
	return
	
	nav_data.nav_poly.add_outline_at_index(nav_data.poly, nav_data.index)
	nav_data.nav_poly.make_polygons_from_outlines()

func remove():
	return
	
	nav_data.nav_poly.remove_outline(nav_data.index)
	nav_data.nav_poly.make_polygons_from_outlines()
