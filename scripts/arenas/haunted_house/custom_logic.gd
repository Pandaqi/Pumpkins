extends Node2D

const TRAP_DURATION : float = 15.0

var active_trap = null
var timer = 0.0

export var trap_voting_node_path : NodePath
var trap_voting_node

export var trap_wall_path : NodePath
var trap_wall_container

export var regular_canvas_modulate : Color
onready var canvas_mod = $CanvasModulate

onready var tween = $Tween

onready var actual_switch_timer = $ActualSwitchTimer

func activate():
	trap_voting_node = get_node(trap_voting_node_path)
	trap_wall_container = get_node(trap_wall_path)
	
	for child in trap_wall_container.get_children():
		child.deactivate()
	
	change_trap()

func on_player_death(_p) -> Dictionary:
	return {}

func _physics_process(dt):
	if not active_trap: return

	timer += (1.0 / TRAP_DURATION) * dt
	
	active_trap.update_progress(timer)
	
	if timer >= 1.0: reset()

func reset():
	timer = 0.0
	
	play_switch_effect()

func change_trap():
	var voted_option = trap_voting_node.request_and_reset_results()
	var active_index = 0
	if active_trap: active_index = active_trap.index
	
	if voted_option < 0:
		voted_option = active_index + (randi() % 3) + 1
	
	voted_option = voted_option % 4
	
	var new_trap = trap_wall_container.get_node("Wall" + str(voted_option))
	
	if active_trap: active_trap.deactivate()
	new_trap.activate()
	
	active_trap = new_trap

func play_switch_effect():
	tween.interpolate_property(canvas_mod, "color",
		regular_canvas_modulate, Color(0,0,0), 0.25,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	actual_switch_timer.wait_time = 0.25
	actual_switch_timer.start()

	tween.interpolate_property(canvas_mod, "color",
		Color(0,0,0), Color(2,2,2), 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.25)
	
	tween.interpolate_property(canvas_mod, "color",
		Color(2,2,2), Color(0,0,0), 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.35)
	
	tween.interpolate_property(canvas_mod, "color",
		Color(0,0,0), regular_canvas_modulate, 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		0.45)
	
	tween.start()

func _on_ActualSwitchTimer_timeout():
	change_trap()
