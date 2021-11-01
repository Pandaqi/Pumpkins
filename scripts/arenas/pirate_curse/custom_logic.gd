extends Node2D

const SPAWN_TIMES = { 'min': 7, 'max': 18 }
const MAX_TREASURES : int = 4

onready var map = get_node("/root/Main/Map")
onready var spawner = get_node("/root/Main/Spawner")
onready var treasure_timer = $TreasureTimer

var treasure_scene = preload("res://scenes/arenas/pirate_curse/treasure.tscn")

func activate():
	_on_TreasureTimer_timeout()

func on_player_death(_p) -> Dictionary:
	return {}

func _on_TreasureTimer_timeout():
	place_treasure()
	
	treasure_timer.wait_time = rand_range(SPAWN_TIMES.min, SPAWN_TIMES.max)
	treasure_timer.start()

func place_treasure():
	var num_treasures = get_tree().get_nodes_in_group("Treasures").size()
	if num_treasures >= MAX_TREASURES: return
	
	var t = treasure_scene.instance()
	
	var params = {
		'body_radius': 50.0,
		'avoid_players': 100.0
	}
	var pos = spawner.get_valid_pos(params)
	t.set_position(pos)
	map.entities.add_child(t)
	
	t.modules.status.set_random_type()
	
	var rot = 2*randf()*PI
	var vec = Vector2(cos(rot), sin(rot))
	t.set_rotation(rot)
	t.apply_central_impulse(vec * 50.0)
