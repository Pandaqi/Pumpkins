extends Node2D

const TIMER_BOUNDS = { 'min': 5, 'max': 15 }

var all_dynamic_tombstones = []
var cur_hidden_tombstone = null

onready var map = get_node("/root/Main/Map")
onready var tombstone_timer = $TombstoneTimer
onready var tween = $Tween

var player_controlled_tombstone = preload("res://arenas/tombstone_dynamic.tscn")

func activate():
	all_dynamic_tombstones = get_tree().get_nodes_in_group("Dynamics")
	_on_TombstoneTimer_timeout()

func on_player_death(p) -> Dictionary:
	var t = player_controlled_tombstone.instance()
	t.set_position(p.global_position)
	
	p.modules.status.hide_completely()
	p.modules.input.connect("move_vec", t, "on_move_vec")
	p.modules.input.connect("button_release", t, "on_throw")
	
	map.entities.add_child(t)
	
	return {}

func _on_TombstoneTimer_timeout():
	show_previous_tombstone()
	hide_random_tombstone()
	
	tombstone_timer.wait_time = rand_range(TIMER_BOUNDS.min, TIMER_BOUNDS.max)
	tombstone_timer.start()

func show_previous_tombstone():
	if not cur_hidden_tombstone: return
	
	cur_hidden_tombstone.set_visible(true)
	cur_hidden_tombstone.collision_layer = 1
	cur_hidden_tombstone.collision_mask = 1
	
	# blow away any bodies here
	var area2d = cur_hidden_tombstone.get_node("Area2D")
	var bodies = area2d.get_overlapping_bodies()
	for b in bodies:
		var away_vec = (b.global_position - area2d.global_position).normalized()
		if (b is KinematicBody2D):
			b.modules.knockback.apply(away_vec * 300.0)
		elif (b is RigidBody2D):
			b.apply_central_impulse(away_vec * 300.0)
	
	appear(cur_hidden_tombstone)

func hide_random_tombstone():
	var pick = cur_hidden_tombstone
	while pick == cur_hidden_tombstone:
		pick = all_dynamic_tombstones[randi() % all_dynamic_tombstones.size()]
	
	cur_hidden_tombstone = pick
	
	pick.set_visible(false)
	pick.collision_layer = 0
	pick.collision_mask = 0
	
	disappear(pick)

func appear(obj):
	tween.interpolate_property(obj, "scale",
	Vector2.ZERO, Vector2(1,1), 0.5,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

func disappear(obj):
	tween.interpolate_property(obj, "scale",
	Vector2(1,1), Vector2(0,0), 0.5,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

