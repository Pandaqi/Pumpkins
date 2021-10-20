extends Node2D

const PLAYER_SENSOR_RANGE : float = 300.0

onready var players = get_node("/root/Main/Players")
onready var mode = get_node("/root/Main/ModeManager")
onready var body = get_parent()

var player_num : int = -1

var vel : Vector2
var is_throwing : bool

var num_knives : int
var active_knife_vec : Vector2

var knives_close : Array
var knives_close_hostile : Array
var knives_close_friendly : Array

var collectibles_close : Array

var points : int = 0
var area : float = 0.0

var closest : KinematicBody2D
var vec_to_closest : Vector2
var dist_to_closest : float

var players_close : Array
var num_players_close : int
var vec_away_from_close_players : Vector2
var avg_distance_to_players : float

var params = {}

signal move_vec()

signal button_press()
signal button_release()

func _ready():
	determine_personality()

func set_player_num(num):
	player_num = num

func determine_personality():
	pass

func _physics_process(dt):
	read_situation()
	assemble_movement_vector()
	go_around_obstacles(dt)
	apply_chosen_input()

func read_situation():
	var pos = body.get_global_position()
	
	# information about our own status
	vel = body.modules.mover.last_velocity
	is_throwing = body.modules.slasher.slashing_enabled
	
	num_knives = body.modules.knives.count()
	active_knife_vec = body.modules.knives.get_first_knife_vec()

	points = body.modules.collector.count()
	area = body.modules.shaper.area
	
	# information about knives/stuff we could get in the environment
	knives_close = get_all_knives()
	knives_close_friendly = []
	knives_close_hostile = []
	for knife in knives_close:
		if body.modules.knives.is_mine(knife):
			knives_close_friendly.append(knife)
		else:
			knives_close_hostile.append(knife)
	
	collectibles_close = mode.get_collectibles()
	
	# information about closest player
	closest = players.get_closest_to(pos, body)
	vec_to_closest = ((closest.get_global_position()) - pos).normalized()
	dist_to_closest = ((closest.get_global_position()) - pos).length()
	
	# general information about players
	players_close = players.get_all_within_range(pos, PLAYER_SENSOR_RANGE)
	num_players_close = players_close.size()
	
	var vec = Vector2.ZERO
	for p in players_close:
		vec += (pos - p.get_global_position())
	
	avg_distance_to_players = (vec / float(num_players_close)).length()
	vec_away_from_close_players = (vec / float(num_players_close)).normalized()
	
	# information about winning player
	# TO DO => if they are close to winning, make it a priority to attack them
	# TO DO => if our points are far behind, become more aggressive and take more risks
	
	# information about the physical environment
	# TO DO => Physical bodies blocking our path

func assemble_movement_vector():
	params = { 
		'vec': Vector2.ZERO, 
		'weight': 0,
		'press_button': false,
		'release_button': false,
		'aim_vec': Vector2.ZERO,
		'prevent_attack': false
	}
	
	check_immediate_danger(params)
	stock_resources(params)
	attack(params)

func check_immediate_danger(params):
	var our_pos = body.get_global_position()
	
	# check knives around us
	# (project their position, move away from them)
	var vec_away_from_knives : Vector2 = Vector2.ZERO
	for knife in knives_close_hostile:
		var pos = knife.get_global_position()
		var dist_to_knife = (our_pos - pos).length()
		var vec_to_travel = knife.get_node("Projectile").velocity.normalized()*dist_to_knife
		var projected_pos = pos + vec_to_travel
		
		vec_away_from_knives += (our_pos - projected_pos).normalized()
	
	params.vec += vec_away_from_knives * 10
	params.weight += 10
	
	# check opponents close to us
	# (if their active knife is in our general direction, step out of there)
	var vec_away_from_players : Vector2 = Vector2.ZERO
	for player in players_close:
		var pos = player.get_global_position()
		var knife_vec = player.modules.knives.get_first_knife_vec()
		var vec_to_us = (our_pos - pos).normalized()
		
		if vec_to_us.dot(knife_vec) >= 0.75:
			vec_away_from_players += (knife_vec - vec_to_us).normalized()
	
	params.vec += vec_away_from_players * 10
	params.weight += 10
	
	# optional niceties
	# (if someone is winning, annoy them; if we're far behind, take more risks)
	# TO DO

func stock_resources(params):
	var our_pos = body.get_global_position()
	
	# check knives around us
	# (move towards the closest of them)
	# (if we're out of knives, increase the priority for this)
	var vec_to_knife : Vector2 = Vector2.ZERO
	var closest_dist : float = INF
	for knife in knives_close_friendly:
		var vec = (knife.get_global_position() - our_pos)
		if vec.length() >= closest_dist: continue
		
		closest_dist = vec.length()
		vec_to_knife = vec
	
	var my_weight = 5
	if num_knives <= 0: my_weight = 12
	
	params.vec += vec_to_knife * my_weight
	params.weight += my_weight
	
	# move towards collectibles
	# (if those are a thing in our game mode)
	if mode.has_collectibles():
		var vec_to_collectible : Vector2 = Vector2.ZERO
		var found_something = false
		
		closest_dist = INF
		for c in collectibles_close:
			var vec = (c.get_global_position() - our_pos)
			
			var collectible_is_already_mine = (c.modules.status.player_num == body.modules.status.player_num)
			if collectible_is_already_mine: continue
			if vec.length() >= closest_dist: continue
			
			closest_dist = vec.length()
			vec_to_collectible = vec.normalized()
			
			found_something = true
		
		my_weight = 12
		params.vec += vec_to_collectible * my_weight
		params.weight += my_weight
		
		if found_something:
			params.prevent_attack = true
	
	# optional niceties
	# (purposefully avoid/grab/slash powerups)
	# TO DO

func attack(params):
	# without knives, we cannot attack anyway :p
	if num_knives <= 0: return
	if params.prevent_attack: return
	
	var our_pos = body.get_global_position()
	
	# pick the best target
	# (close to current knife vector, nothing obstructing it)
	var targets = mode.get_targets()
	var targets_ordered = []
	for t in targets:
		var its_ourself = (t == body)
		if its_ourself: continue
		
		var pos = t.get_global_position()
		var vec = (pos - our_pos)
		var vec_norm = vec.normalized()
		var dot = active_knife_vec.dot(vec_norm)
		
		targets_ordered.append({ 'target': t, 'dot': dot, 'vec_to': vec, 'dist': vec.length() })
	
	targets_ordered.sort_custom(self, "target_sort")
	
	var final_target = null
	
	var closest_target = null
	var closest_dist = INF
	
	var min_separation_with_target = 30
	
	for t in targets_ordered:
		var target = t.target
		var start = our_pos
		var end = target.get_global_position()
		var exclusion = [body]
		var result = shoot_raycast(start, end, exclusion)
		
		if t.dist < closest_dist and t.dist > min_separation_with_target:
			closest_dist = t.dist
			closest_target = { 'target': t, 'vec_to': t.vec_to }
		
		if not result: continue
		if not (result.collider == target): continue
		
		final_target = t
		break
	
	# in any case, move towards a target if possible
	var move_towards_target = final_target
	if not final_target: move_towards_target = closest_target
	
	if move_towards_target:
		var my_weight = 1
		params.vec += closest_target.vec_to*my_weight
		params.weight += my_weight
	
	# no target, but we're in throw mode?
	# just throw now, so we can continue moving elsewhere
	var slasher = body.modules.slasher
	if is_throwing:
		if not move_towards_target or slasher.held_too_long():
			params.release_button = true
	if not final_target: return
	
	# if we're throwing and close enough, THROW IT
	var target_pos = final_target.target.get_global_position()
	if is_throwing:
		if final_target.dot >= 0.9:
			var time_is_right = slasher.in_long_throw_mode() or slasher.pos_within_range(target_pos)
			if time_is_right:
				params.release_button = true
	
	# if we're not throwing, but a suitable candidate exists? START THROWING
	else:
		if final_target.dot >= 0.6 or final_target.dist <= 40:
			params.press_button = true
	
	params.aim_vec = final_target.vec_to

func target_sort(a,b):
	return a.dot < b.dot

func shoot_raycast(start, end, exclude = [], col_layer = 1 + 2 + 4 + 8):
	var space_state = get_world_2d().direct_space_state 
	return space_state.intersect_ray(start, end, exclude, col_layer)

func shoot_triple_raycast(start, vec, exclude, col_layer = 1):
	var offset = 0.25*PI
	var ortho_vec = vec.rotated(PI)
	
	var rc1 = shoot_raycast(start, start + vec, exclude, col_layer)
	var rc2 = shoot_raycast(start, start + 0.5*ortho_vec + vec, exclude, col_layer)
	var rc3 = shoot_raycast(start, start - 0.5*ortho_vec + vec, exclude, col_layer)
	
	if rc1: return rc1
	if rc2: return rc2
	if rc3: return rc3
	return null

func go_around_obstacles(dt):
	var final_vec = (params.vec / float(params.weight)).normalized()
	var tries = {
		'left': final_vec,
		'right': final_vec
	}
	
	params.final_vec = final_vec
	
	if is_throwing: return
	
	var start = body.get_global_position()
	var mover = body.modules.mover
	var shaper = body.modules.shaper
	
	var rel_speed = mover.get_speed_with_delta(dt) + shaper.approximate_radius()
	var rel_vec = (final_vec*rel_speed)
	var exclude = [body]

	if not shoot_triple_raycast(start, rel_vec, exclude): return
	
	var cur_dir = 'right'
	var rot_step = 0.25*PI
	var num_tries = 0
	var max_num_tries = (2*PI)/rot_step
	
	while num_tries < max_num_tries:
		var rot_dir = 1 if cur_dir == 'right' else -1
		tries[cur_dir] = tries[cur_dir].rotated(rot_dir * rot_step)
		
		rel_vec = (tries[cur_dir]*rel_speed)
		
		if not shoot_triple_raycast(start, rel_vec, exclude): 
			final_vec = tries[cur_dir]
			break
		
		if cur_dir == 'right':
			cur_dir = 'left'
		else:
			cur_dir = 'right'
		
		num_tries += 1
	
	var is_mostly_surrounded = (num_tries > 0.5*max_num_tries)
	if is_mostly_surrounded:
		print("MOSTLY SURROUNDED")
		pass
	
	params.final_vec = final_vec

func apply_chosen_input():
	# movement
	var final_vec = params.final_vec
	
	var override_with_aim_vec = is_throwing or params.press_button
	if override_with_aim_vec:
		final_vec = params.aim_vec
	
	emit_signal("move_vec", final_vec)
	
	# button press/release
	if params.press_button:
		emit_signal("button_press")
	if params.release_button:
		emit_signal("button_release")

func get_all_knives():
	return get_all_knives_within_range(INF)

func get_all_knives_within_range(radius):
	var knives = get_tree().get_nodes_in_group("Knives")
	var our_pos = body.get_global_position()
	var arr = []
	for knife in knives:
		var their_pos = knife.get_global_position()
		var dist = (their_pos - our_pos).length()
		if knife.get_node("Projectile").being_held: continue
		if dist > radius: continue
		
		arr.append(knife)
	
	return arr
