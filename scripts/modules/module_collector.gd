extends Node2D

const MAGNET_STRENGTH : float = 10.0

var is_hungry : bool = false
onready var body = get_parent()
onready var magnet_area = $MagnetArea
onready var main_node = get_node("/root/Main")
onready var mode = get_node("/root/Main/ModeManager")
onready var collectors = get_node("/root/Main/Collectors")
onready var particles = get_node("/root/Main/Particles")

var num_collected : int = 0

var multiplier : int = 1
var collection_disabled : bool = false
var magnet_enabled : bool = false

func count():
	return num_collected

func collect(dc):
	if dc == 0: return
	
	num_collected += dc
	
	main_node.player_progression(body.modules.status.player_num)
	collectors.update_team_count(body.modules.status.team_num)
	
	GlobalAudio.play_dynamic_sound(body, "collect")
	
	var final_string = "+" + str(dc)
	if dc < 0: final_string = str(dc)
	
	particles.create_collectible_particle(body.global_position, final_string)

func disable_collection():
	collection_disabled = true

func enable_collection():
	collection_disabled = false
	for b in $Area2D.get_overlapping_bodies():
		_on_Area2D_body_entered(b)

func enable_magnet():
	magnet_enabled = true

func disable_magnet():
	magnet_enabled = false

func check_magnet(_dt):
	if not magnet_enabled: return
	
	for other_body in magnet_area.get_overlapping_bodies():
		var vec_to_me = (body.get_global_position() - other_body.get_global_position()).normalized()
		
		if other_body.is_in_group("Unpullables"): continue
		
		# Static bodies are unpullable by default (as 99% of them are)
		# and need an exception to become pullable
		if other_body is StaticBody2D and not other_body.is_in_group("Pullables"): continue
		
		if other_body is RigidBody2D:
			other_body.apply_central_impulse(vec_to_me * MAGNET_STRENGTH)
		elif other_body is KinematicBody2D:
			other_body.move_and_slide(vec_to_me * MAGNET_STRENGTH)
		elif other_body is StaticBody2D:
			other_body.set_position(other_body.get_position() + vec_to_me*MAGNET_STRENGTH)
	

func _on_Area2D_body_entered(other_body):
	if collection_disabled: return
	
	if not other_body.is_in_group("Parts"): return
	
	var success = false
	
	# NOTE: being hungry means you GROW _and_ you eat non-player parts
	# that's the difference with regular eating, and that's why it still executes
	if is_hungry:
		success = true
		body.modules.grower.grow(0.1)
	
	if mode.can_eat_player_parts(): 
		var status = other_body.modules.status
		var body_is_player_part = status.is_from_a_player()
		var body_is_mine = status.is_from_specific_player(body.modules.status.player_num)
		if body_is_player_part and not body_is_mine:
			success = true
	
	if success:
		other_body.queue_free()
		collect(1 * multiplier)

func _physics_process(dt):
	check_magnet(dt)
