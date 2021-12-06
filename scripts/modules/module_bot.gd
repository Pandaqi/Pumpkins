extends Node2D

const PLAYER_SENSOR_RANGE : float = 900.0
const THROWABLE_VIEW_DISTANCE : float = 600.0
const MIN_SEPARATION_WITH_TARGET : float = 100.0

const POWERUP_SENSOR_DIST : float = 300.0

onready var players = get_node("/root/Main/Players")
onready var mode = get_node("/root/Main/ModeManager")
onready var body = get_parent()

onready var nav = get_node("/root/Main/Navigation")

var player_num : int = -1
var use_navigation : bool = true

var vel : Vector2
var is_throwing : bool

var unstuck_mode : bool = false
var unstuck_vec : Vector2 = Vector2.ZERO

var num_knives : int
var active_knife_vec : Vector2

var throwables_hostile : Array
var throwables_friendly : Array
var last_chosen_throwable_target = null
var vec_away_from_throwables : Vector2
var vec_to_throwable_resource : Vector2

var collectibles : Array
var vec_to_collectible : Vector2
var last_chosen_collectible = null

var targets : Array

var points : int = 0
var area : float = 0.0

var players_close : Array
var num_players_close : int
var vec_away_from_players : Vector2
var avg_distance_to_players : float

var params = {}

var debug_draw : bool = false
var debug_path = null
var debug_raycasts = []

const IDLE_FRAMES_UNTIL_ACTION : int = 300
var movement_last_X_frames = []

var ignore_best_option : bool = false

signal move_vec(vec, dt)

signal button_press()
signal button_release()

func _ready():
	determine_personality()

func set_player_num(num):
	player_num = num

func determine_personality():
	pass

func _physics_process(dt):
	debug_raycasts = []
	
	check_for_standstill()
	
	read_situation()
	assemble_movement_vector()
	go_around_obstacles(dt)
	apply_chosen_input(dt)
	
	update()

func check_for_standstill():
	if movement_last_X_frames.size() < (IDLE_FRAMES_UNTIL_ACTION-10): return
	if unstuck_mode: return
	if is_throwing: return
	
	var amount_moved = 0.0
	for vec in movement_last_X_frames:
		amount_moved += vec.length()
	
	var avg_amount_moved = amount_moved/float(movement_last_X_frames.size())
	var ideal_avg_amount_moved = body.modules.mover.ideal_movement_per_frame

	if avg_amount_moved > 0.5*ideal_avg_amount_moved: return

	var vec = -body.modules.mover.last_velocity
	if vec.length() <= 0.03:
		var rot = body.rotation
		vec = -Vector2(cos(rot), sin(rot))
	
	enable_unstuck_mode(vec)
	movement_last_X_frames = []

func read_situation():
	var pos = body.get_global_position()
	
	# information about our own status
	vel = body.modules.mover.last_velocity
	is_throwing = body.modules.slasher.slashing_enabled
	
	num_knives = body.modules.knives.count()
	active_knife_vec = body.modules.knives.get_first_knife_vec()

	points = body.modules.collector.count()
	area = body.modules.shaper.area
	
	#
	# information about throwables we could grab (friendly)
	# or must flee from (hostile)
	#
	var throwables = get_all_throwables()
	for i in range(throwables.size()-1,-1,-1):
		var t = throwables[i]
		if t.modules.status.being_held: 
			throwables.remove(i)
			continue
	
	throwables_friendly = []
	throwables_hostile = []
	for t in throwables:
		if body.modules.knives.is_mine(t):
			throwables_friendly.append(t)
		else:
			throwables_hostile.append(t)
	
	# also include throwables from powerups, as those are just as good as picking up an existing knife
	var ps = get_tree().get_nodes_in_group("PowerupsRevealed")
	var powerup_throwables = []
	for p in ps:
		if p.is_throwable: powerup_throwables.append(p)
	
	throwables_friendly += powerup_throwables
	
	throwables_friendly = sort_based_on_distance(throwables_friendly)
	throwables_hostile = sort_based_on_distance(throwables_hostile)
	
	vec_away_from_throwables = Vector2.ZERO
	var total_weight : float = 0.0
	for t in throwables_hostile:
		if t.dist >= THROWABLE_VIEW_DISTANCE: continue
		
		var away_from_projected_vec = (t.projected_pos - body.global_position)
		if away_from_projected_vec.length() > 80.0: continue
		
		var weight = 1.0 - (t.dist / THROWABLE_VIEW_DISTANCE)
		
		vec_away_from_throwables += weight*away_from_projected_vec.normalized()
		total_weight += weight
	
	if total_weight > 0: vec_away_from_throwables /= total_weight
	
	#
	# information about collectibles in the environment
	#
	collectibles = mode.get_collectibles()
	collectibles = sort_based_on_distance(collectibles)
	
	for i in range(collectibles.size()-1,-1,-1):
		var c = collectibles[i]
		if c is Dictionary: c = c.body
		
		var collectible_is_already_mine = (c.modules.status.player_num == body.modules.status.player_num)
		
		if collectible_is_already_mine:
			collectibles.remove(i)
			continue
	
	#
	# Information about "targets" (these depend on the game mode)
	# (Dicey Slicey = players, Dwarfing Dumplings = huge dumplings, etc.)
	#
	targets = mode.get_targets()
	targets = sort_based_on_dot_product(targets)
	
	for i in range(targets.size()-1,-1,-1):
		var t = targets[i]
		
		# don't target ourself
		var its_ourself = (t.body == body)
		if its_ourself: 
			targets.remove(i)
			continue
		
		# don't target anyone who still has a tutorial going
		if t.body.is_in_group("Players"):
			if t.body.modules.has('tutorial'):
				targets.remove(i)
				continue
		
		# don't target our own teammates
		# (this includes our own huge dumpling)
		if body.modules.status.same_team(t.body):
			targets.remove(i)
			continue
	
	#
	# general information about players
	#
	players_close = players.get_all_within_range(pos, PLAYER_SENSOR_RANGE)
	num_players_close = players_close.size()
	players_close = sort_based_on_distance(players_close)
	
	#
	# information about other players
	#
	
	# check opponents close to us
	# (if their active knife is in our general direction, step out of there)
	vec_away_from_players = Vector2.ZERO
	total_weight = 0.0
	for player in players_close:
		var knife_vec = player.body.modules.knives.get_first_knife_vec()
		if not knife_vec: continue

		var vec_to_us = -player.vec
		if vec_to_us.dot(knife_vec) < 0.5: continue
		
		var vec_away = (vec_to_us - knife_vec)
		var weight = 1.0 - (vec_away.length() / PLAYER_SENSOR_RANGE)
		
		vec_away_from_players += weight*vec_away.normalized()
		total_weight += weight
	
	if total_weight > 0: 
		vec_away_from_players /= total_weight
	
	# information about winning player
	# TO DO => if they are close to winning, make it a priority to attack them
	# TO DO => if our points are far behind, become more aggressive and take more risks

func assemble_movement_vector():
	params = { 
		'vec': Vector2.ZERO, 
		'weight': 0,
		'press_button': false,
		'release_button': false,
		'aim_vec': Vector2.ZERO,
		'prevent_attack': false
	}
	
	check_immediate_danger()
	stock_resources()
	attack()
	
	params.final_vec = (params.vec / float(params.weight)).normalized()

func check_immediate_danger():
	var weight = 10
	
	params.vec += vec_away_from_throwables.normalized() * weight
	params.weight += weight
	
	weight = 10
	params.vec += vec_away_from_players.normalized() * weight
	params.weight += weight
	
	# optional niceties
	# (if someone is winning, annoy them; if we're far behind, take more risks)
	# TO DO

func stock_resources():
	var our_pos = body.get_global_position()
	var my_weight
	
	# check knives around us
	# (move towards the closest of them)
	# (if we're out of knives, increase the priority for this)
	if throwables_friendly.size() > 0:
		var closest_throwable = throwables_friendly[0]
		var vec_to_closest = (closest_throwable.body.global_position - our_pos).normalized()
		
		var path = null
		var counter = 0
		while not path and counter < throwables_friendly.size():
			var t = throwables_friendly[counter]
			if t == last_chosen_throwable_target and ignore_best_option:
				counter += 1 
				continue
			
			path = get_path_to_target(t.body.global_position)
			if path.size() < 2:
				path = null
			else:
				vec_to_closest = get_next_vec_on_path(path)
			
			counter += 1
		
		debug_path = path

		my_weight = 2
		if num_knives <= 0: my_weight = 12
		
		vec_to_throwable_resource = vec_to_closest
	
		params.vec += vec_to_closest * my_weight
		params.weight += my_weight
		
		var new_throwable_target = closest_throwable
		if path:
			new_throwable_target = throwables_friendly[counter-1]
		
		last_chosen_throwable_target = new_throwable_target
	
	#
	# If the mode has collectibles
	# Find the closest one with a path, or just the closest one
	# Give it a really high priority
	#
	if collectibles.size() > 0:
		var closest_collectible = collectibles[0]
		var vec_to_closest = (closest_collectible.body.global_position - our_pos).normalized()
		
		var path = null
		var counter = 0
		
		while not path and counter < collectibles.size():
			var c = collectibles[counter]
			if c == last_chosen_collectible and ignore_best_option: 
				counter += 1
				continue
			
			path = get_path_to_target(c.body.global_position)
			if path.size() < 2:
				path = null
			else:
				var new_vec = get_next_vec_on_path(path)
				if new_vec.length() > 0.03:
					vec_to_closest = new_vec
			
			counter += 1
		
		my_weight = 12
		params.vec += vec_to_closest * my_weight
		params.weight += my_weight
		
		vec_to_collectible = vec_to_closest
		
		var new_collectible_target = closest_collectible
		if path:
			new_collectible_target = collectibles[counter-1]
		
		last_chosen_collectible = new_collectible_target
		
		# TO DO: Not sure about this, ALWAYS prevent attack if collectible is known? Seems a bit too strong
		params.prevent_attack = true
	
	#
	# If the mode has powerups, we go for good ones (if revealed)
	#
	var powerups = get_tree().get_nodes_in_group("PowerupsRevealed")
	var away_from_bad_ps_vec : Vector2 = Vector2.ZERO
	var away_weight : float = 0.0
	
	var toward_good_ps_vec : Vector2 = Vector2.ZERO
	var toward_weight : float = 0.0
	
	if powerups.size() > 0:
		powerups = sort_based_on_distance(powerups)
		
		for p in powerups:
			if p.dist >= POWERUP_SENSOR_DIST: break
			
			var vec = p.vec
			var weight = 1.0 - (p.dist / POWERUP_SENSOR_DIST)
			if p.body.get_data().has('bad'):
				away_from_bad_ps_vec += weight*-1*vec
				away_weight += weight
			else:
				toward_good_ps_vec += weight*vec
				toward_weight += weight
		
		if toward_weight > 0: toward_good_ps_vec /= toward_weight
		if away_weight > 0: away_from_bad_ps_vec /= away_weight
		
		var overall_weight = 2.0
		params.vec += away_from_bad_ps_vec.normalized()*overall_weight
		params.weight += overall_weight 
		
		params.vec += toward_good_ps_vec.normalized()*overall_weight
		params.weight += overall_weight 

func get_next_vec_on_path(path):
	var our_pos = body.global_position
	var close_enough = true
	var vec
	var counter = 0
	
	while close_enough and counter < path.size() - 1:
		var dist = (path[counter] - our_pos).length()
		vec = (path[counter+1] - path[counter]).normalized()
		close_enough = dist <= 20
		
		counter += 1
	
	return vec

func attack():
	# without knives or targets, we cannot attack
	if num_knives <= 0: return
	if params.prevent_attack: return
	if targets.size() <= 0: return
	
	var our_pos = body.get_global_position()
	var closest_target = null
	var cant_reach = true
	var counter = 0
	var sliceable_in_the_way = false
	
	while cant_reach and counter < targets.size():
		closest_target = targets[counter]
		counter += 1
		
		var start = our_pos
		var end = closest_target.body.global_position
		var exclusion = [body]
		var rc_params = shoot_raycast(start, end, exclusion, 1 + 2 + 4 + 8, closest_target.body)
		
		if not rc_params.result: continue
		if rc_params.sliceable_in_front: sliceable_in_the_way = true
		if not (rc_params.result.collider == closest_target.body): continue
		
		cant_reach = false
	
	# we've been throwing a while without success? just release and try again
	if is_throwing and body.modules.slasher.held_too_long():
		params.release_button = true
	
	# there's an obstacle between us, but it's sliceable? Hit it!
	if cant_reach and sliceable_in_the_way:
		params.release_button = true
	
	# no good target? Just resort to the first one
	if cant_reach: 
		closest_target = targets[0]

	# we move closer, up to a certain limit
	# (if within that, move further away instead)
	var move_type = 'closer'
	var move_vec = closest_target.vec
	if closest_target.dist < MIN_SEPARATION_WITH_TARGET:
		move_type = 'further'
		move_vec *= -1
	
	var my_weight = 1
	params.vec += move_vec*my_weight
	params.weight += my_weight

	# if we're throwing and close enough, THROW IT
	if not cant_reach:
		if is_throwing:
			if closest_target.dot >= 0.94:
				params.release_button = true
		
		# if we're not throwing, but a suitable candidate exists?
		# (within right aim and distance)
		# START THROWING
		else:
			if closest_target.dot >= 0.4 and not move_type == 'further':
				params.press_button = true
	
	var active_knife_rotation = body.modules.knives.get_first_knife().rotation
	params.aim_vec = closest_target.vec.rotated(-active_knife_rotation)

func shoot_raycast(start, end, exclude = [], col_layer = 1 + 2 + 4 + 8, target_body = null):
	var space_state = get_world_2d().direct_space_state 
	
	debug_raycasts.append({ 'from': start, 'to': end })
	
	var hitting_sliceable = true
	var sliceable_in_front = false
	
	var result
	while hitting_sliceable:
		hitting_sliceable = false
		result = space_state.intersect_ray(start, end, exclude, col_layer)
		
		if result and result.collider.is_in_group("Sliceables") and result.collider != target_body:
			exclude.append(result.collider)
			hitting_sliceable = true
			sliceable_in_front = true

	return {
		'result': result,
		'sliceable_in_front': sliceable_in_front
	}

func moving_will_hit_something(start, vec):
	var shaper = body.modules.shaper
	
	var extra_look_ahead = 15
	var ray_length = abs(shaper.bounding_box.y.max) + extra_look_ahead
	var ortho_vec = vec.rotated(0.5*PI)
	
	var body_shrink_factor = 0.8
	
	var exclude = [body]
	var col_layer = 1
	
	# try straight ahead
	var rc1 = shoot_raycast(start, start + vec*ray_length, exclude, col_layer)
	if rc1.result: return rc1.result
	
	# try right edge of our body
	var offset_length = body_shrink_factor*abs(shaper.bounding_box.x.max)
	var new_start = start + ortho_vec*offset_length
	var rc2 = shoot_raycast(new_start, new_start + vec*ray_length, exclude, col_layer)
	if rc2.result: return rc2.result
	
	# try left edge of our body
	offset_length = body_shrink_factor*abs(shaper.bounding_box.x.min)
	new_start = start - ortho_vec*offset_length
	
	var rc3 = shoot_raycast(new_start, new_start + vec*ray_length, exclude, col_layer)
	if rc3.result: return rc3.result
	
	return null

func go_around_obstacles(_dt):
	var final_vec = params.final_vec
	var original_vec = params.final_vec
	var tries = {
		'left': final_vec,
		'right': final_vec
	}
	
	if unstuck_mode: 
		params.final_vec = unstuck_vec
		return
	if is_throwing: return
	
	var start = body.get_global_position()

	if not moving_will_hit_something(start, final_vec): return
	
	var cur_dir = 'right'
	var rot_step = 0.05*PI
	var num_tries = 0
	var max_num_tries = (2*PI)/rot_step
	
	while num_tries < max_num_tries:
		var rot_dir = 1 if cur_dir == 'right' else -1
		tries[cur_dir] = tries[cur_dir].rotated(rot_dir * rot_step)
		
		var try_vec = tries[cur_dir]
		
		if not moving_will_hit_something(start, try_vec): 
			final_vec = try_vec
			break
		
		if cur_dir == 'right':
			cur_dir = 'left'
		else:
			cur_dir = 'right'
		
		num_tries += 1
	
	var is_mostly_surrounded = (original_vec.dot(final_vec) < 0.8)
	if is_mostly_surrounded:
		enable_unstuck_mode(final_vec)
	
	params.final_vec = final_vec

func apply_chosen_input(dt):
	# movement
	# (or aiming, if we've chosen to start/continue throwing)
	var final_vec = params.final_vec
	
	var override_with_aim_vec = is_throwing or params.press_button
	if override_with_aim_vec: final_vec = params.aim_vec
	
	# button press/release
	if params.press_button:
		emit_signal("button_press")
	if params.release_button:
		if not is_throwing: emit_signal("button_press")
		emit_signal("button_release")
	
	emit_signal("move_vec", final_vec, dt)

func get_all_throwables():
	return get_tree().get_nodes_in_group("Throwables")

func enable_unstuck_mode(vec):
	$UnstuckTimer.start()
	$OptionIgnoreTimer.start()
	unstuck_vec = vec
	unstuck_mode = true
	
	ignore_best_option = true

func disable_unstuck_mode():
	unstuck_mode = false

func _on_UnstuckTimer_timeout():
	disable_unstuck_mode()

func _draw():
	if not debug_draw: return
	
	for rc in debug_raycasts:
		draw_line(to_local(rc.from), to_local(rc.to), Color(1,0,0), 5)
	
	if debug_path:
		for i in range(debug_path.size()-1):
			draw_line(to_local(debug_path[i]), to_local(debug_path[i+1]), Color(0,0,0), 5)
	
	var length = 20
	var danger_vec = vec_away_from_players.rotated(-body.rotation)
	draw_line(Vector2.ZERO, danger_vec * length, Color(0,1,0), 5)
	
	var resource_vec = vec_to_throwable_resource.rotated(-body.rotation)
	draw_line(Vector2.ZERO, resource_vec * length, Color(0,0,0), 5)

# Navigation pathing
func get_path_to_target(target_pos):
	# NOTE: third parameter is optimize => has issues
	var our_pos = body.global_position
	var nav_data = nav.get_fitting_nav(body)
	
	var nav_poly = nav_data.poly
	var nav_margin = nav_data.margin
	
	var new_path = nav_poly.get_simple_path(our_pos, target_pos)
	
	var max_tries = 10
	var num_tries = 0
	while path_contains_bounds(new_path) and num_tries < max_tries:
		target_pos = 0.5*(our_pos + target_pos)
		new_path = nav_poly.get_simple_path(our_pos, target_pos)
		num_tries += 1
	
	# if there's simply no path, return that
	if num_tries >= max_tries:
		print("NO PATH POSSIBLE; simply not possible")
		return []
	
	# if we're going to end too far away from our wanted path, it's considered an invalid path
#	if (new_path[new_path.size()-1] - target_pos).length() > (nav_margin + 10):
#		print("NO PATH POSSIBLE; too far away")
#		return []
	
	return new_path
	
func path_contains_bounds(arr):
	for point in arr:
		if point.x <= 0 or point.x >= 1919 or point.y <= 0 or point.y >= 1079: return true
	
	return false

func sort_based_on_distance(arr):
	var temp_arr = []
	for b in arr:
		var vec = (b.global_position - body.global_position)
		var projected_pos = Vector2.ZERO
		
		if b.is_in_group("Throwables"):
			var vec_to_travel = b.modules.mover.velocity.normalized()*vec.length()
			projected_pos = b.global_position + vec_to_travel
		
		temp_arr.append({
			'body': b,
			'vec': vec.normalized(),
			'dist': vec.length(),
			'projected_pos': projected_pos
		})
	
	temp_arr.sort_custom(self, "distance_sort")
	return temp_arr

func sort_based_on_dot_product(arr):
	var temp_arr = []
	for b in arr:
		var vec = (b.global_position - body.global_position)
		var dot = active_knife_vec.dot(vec.normalized())
		
		temp_arr.append({ 
			'body': b, 
			'dot': dot, 
			'vec': vec.normalized(), 
			'dist': vec.length() 
		})
	
	temp_arr.sort_custom(self, "target_sort")
	return temp_arr

# This sorts based on distance, ascending
func distance_sort(a,b):
	return a.dist < b.dist

# This sorts based on dot product, descending
# (Because a HIGHER dot product means our knife vector is MORE CLOSELY ALIGNED, and thus better)
func target_sort(a,b):
	return a.dot > b.dot

func _on_Mover_moved(amount):
	movement_last_X_frames.append(amount)
	
	if movement_last_X_frames.size() >= IDLE_FRAMES_UNTIL_ACTION:
		movement_last_X_frames.pop_front()

func _on_OptionIgnoreTimer_timeout():
	ignore_best_option = false
