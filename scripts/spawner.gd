extends Node2D

func get_valid_pos(params = {}):
	var pos
	var bad_choice = true
	var num_tries = 0
	var max_tries = 600
	
	while bad_choice:
		pos = get_random_inner_position(params)
		num_tries += 1
		
		if params.has('body_radius'):
			if num_tries < 300 and inside_physics_body(pos, params.body_radius): continue
		
		if params.has('avoid_players'):
			if num_tries < 100 and too_close_to_group(pos, params.avoid_players, "Players"): continue
		
		if params.has('avoid_powerups'):
			if num_tries < 200 and too_close_to_group(pos, params.avoid_powerups, "Powerups"): continue
		
		if params.has('avoid_targets'):
			if num_tries < 300 and too_close_to_group(pos, params.avoid_targets, "Targets"): continue
		
		if params.has('avoid_group'):
			if num_tries < 300 and too_close_to_group(pos, params.avoid_group_dist, params.avoid_group): continue
		
		bad_choice = false
		
		if num_tries >= max_tries: break
	
	return pos

func out_of_bounds(pos):
	var margin = 30
	return pos.x < margin or pos.x > (1920.0 - margin) or pos.y < margin or pos.y > (1080.0 - margin)

func get_random_inner_position(params = {}):
	var edge_margin = 60
	if params.has('edge_margin'):
		edge_margin = params.edge_margin
	
	var vp_without_edge = Vector2(1920-2*edge_margin,1080-2*edge_margin) 
	return Vector2(randf(), randf())*vp_without_edge + Vector2(1,1)*edge_margin

func inside_physics_body(pos, radius : float = 20.0):
	var space_state = get_world_2d().direct_space_state
	
	var margin = 10 # it's okay if things are _a little bit_ inside bodies
	var shp = CircleShape2D.new()
	shp.radius = radius - margin
	
	var query_params = Physics2DShapeQueryParameters.new()
	query_params.set_shape(shp)
	query_params.transform.origin = pos # VERY IMPORTANT, otherwise we only check Vector2.ZERO
	
	var result = space_state.intersect_shape(query_params)
	if not result: return false
	
	for res in result:
		if not (res.collider is PhysicsBody2D): continue
		return true
	
	return false

func too_close_to_group(pos, min_separation_dist : float = 50.0, group : String = "Players"):
	var all = get_tree().get_nodes_in_group(group)
	for obj in all:
		var dist = (obj.get_global_position() - pos).length()
		if dist >= min_separation_dist: continue
		return true
	return false
