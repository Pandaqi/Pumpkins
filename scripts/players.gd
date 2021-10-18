extends Node

const DEFAULT_PLAYER_RADIUS : float = 25.0
const MIN_DIST_BETWEEN_PLAYERS : float = 200.0

var num_players
var player_scene = preload("res://scenes/player.tscn")

var pumpkin_shape_scene = preload("res://PumpkinShapes.tscn")
var pumpkin_shapes = []

onready var main_node = get_parent()
onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")

func activate():
	load_pumpkin_shapes()
	create_players()

func load_pumpkin_shapes():
	var arr = []
	
	var ps = pumpkin_shape_scene.instance()
	for child in ps.get_children():
		if not (child is CollisionPolygon2D): continue
		
		arr.append(Array(child.polygon))
		
	pumpkin_shapes = arr

func select_random_pumpkin_shape():
	return pumpkin_shapes[randi() % pumpkin_shapes.size()]

func create_players():
	num_players = GlobalInput.get_player_count()
	
	var params = { 'body_radius': DEFAULT_PLAYER_RADIUS, 'avoid_players': MIN_DIST_BETWEEN_PLAYERS }
	
	for i in range(num_players):
		var p = player_scene.instance()
		map.entities.add_child(p)
		p.set_position(spawner.get_valid_pos(params))
		p.modules.shaper.create_from_shape(select_random_pumpkin_shape())
		p.modules.status.set_player_num(i)
		
		
