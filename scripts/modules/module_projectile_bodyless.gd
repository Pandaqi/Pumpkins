extends Node2D

const GHOST_RAND_ROTATION : float = 0.05
const GHOST_SLOWDOWN : float = 0.995

const VELOCITY_LEFT_AFTER_DEFLECTION : float = 0.9
const MIN_TIME_BETWEEN_DEFLECTIONS : float = 50.0 # milliseconds

const MIN_DIST_BEFORE_SLICE : float = 90.0
const MIN_DIST_BEFORE_CERTAIN_SLICE : float = 180.0
const MIN_DIST_LONG_THROW_BONUS : float = 1000.0

const LONG_THROW_EXTRA_SLICE_PROB : float = 1.0

onready var body = get_parent()

onready var particles = get_node("/root/Main/Particles")
onready var slicer = get_node("/root/Main/Slicer")
onready var mode = get_node("/root/Main/ModeManager")

var ignore_deflections : bool = false
var last_deflection_time : float

#
# Polling the results from the (fake) body
#
func _physics_process(_dt):
	poll_special_hits()
	poll_front_raycast()
	poll_back_raycast()
	poll_side_raycast()

func poll_front_raycast():
	var result = body.modules.fakebody.front_raycast
	if not result: return
	
	var hit_body = result.collider
	if not hit_body or not is_instance_valid(hit_body): return
	var succesful_grab = body.modules.grabber.try_grabbing(hit_body)
	if succesful_grab: return
	
	if hit_body.is_in_group("Dumplings"):
		handle_dumpling(hit_body)
	
	if hit_body.is_in_group("Customs"):
		if hit_body.script and hit_body.has_method("on_throwable_hit"):
			hit_body.on_throwable_hit(body)
		else:
			print("Tried to call custom function, but not possible.")
	
	# a boomerang always returns after any hit
	body.modules.mover.boomerang_state = "returning"

	var handled = false
	if hit_body.is_in_group("Sliceables"):
		handled = slice_through_body(hit_body)
	
	if body.modules.status.type == "ghost_knife": 
		var ghost_knife_random_removal_prob = 0.05 # to prevent ghost knives from lingering around too long and be annoying
		if handled and (hit_body.is_in_group("Players") or randf() <= ghost_knife_random_removal_prob):
			body.queue_free()
		return
	
	if handled: 
		if hit_body.is_in_group("ThrowableDeleters"): 
			body.modules.status.delete()
		return
	
	if hit_body.is_in_group("Stuckables"):
		handled = get_stuck(result)
		
		# TO DO: Clean this shit up
		if handled:
			var custom_behavior = (hit_body.script and hit_body.has_method("on_knife_entered"))
			
			if custom_behavior:
				hit_body.on_knife_entered(body)
			else:
				if GlobalDict.cfg.stuck_reset:
					body.modules.owner.remove()
	
	if handled: return
	
	deflect(result)
	handled = true

func poll_back_raycast():
	var result = body.modules.fakebody.back_raycast
	if not result: return
	
	grab_throwable(result.collider)

func poll_side_raycast():
	var result = body.modules.fakebody.side_raycasts
	if not result: return
	
	grab_throwable(result.collider)

func poll_special_hits():
	for nonsolid in body.modules.fakebody.nonsolids_hit:
		if nonsolid.script and nonsolid.has_method("on_throwable_hit"):
			nonsolid.on_throwable_hit()
		
		if nonsolid.is_in_group("Mist"):
			body.modules.mover.rotate_velocity((randf()-0.5)*0.3*PI)

#
# Calculating the interactions we have
#

func grab_throwable(hit_body):
	if not hit_body or not is_instance_valid(hit_body): return
	body.modules.grabber.try_grabbing(hit_body)

# TO DO: Check if the attacking object (ourselves, "body") is an actual knife?
func handle_dumpling(obj):
	var victim = obj.modules.owner.get_owner()
	var attacker = body.modules.owner.get_owner()
	if not victim or not attacker: return
	
	victim.modules.knives.check_dumpling_hit(obj, attacker)

func get_stuck(result):
	if body.modules.status.is_stuck: return true
	if body.modules.status.type == "boomerang": return false
	
	var hit_body = result.collider
	
	body.modules.mover.set_velocity(Vector2.ZERO)
	body.set_position(result.position)
	body.set_rotation(-result.normal.angle())
	
	body.modules.status.reset_to_stuck_state()
	
	GlobalAudio.play_dynamic_sound(body, "thud")
	particles.create_explosion_particles(body.global_position)
	
	body.modules.fakebody.reset_all()
	body.modules.fakebody.reset_collision_exceptions()
	
	
	if not (hit_body is StaticBody2D):
		var old_rotation = body.global_rotation
		var old_position = body.global_position
		
		body.get_parent().remove_child(body)
		hit_body.add_child(body)
		
		body.set_rotation(old_rotation - hit_body.rotation)
		body.set_position(hit_body.to_local(old_position))
		
		body.modules.status.reset_to_held_and_stuck_state()
	
	return true

func check_repellant_powerup(obj):
	if not obj.is_in_group("Players"): return false
	if not obj.modules.powerups.repel_knives: return false
	return true

func slice_through_body(obj):
	var is_player = obj.is_in_group("Players")
	
	# projectiles with a real body can NEVER slice something
	if body.modules.fakebody.has_real_body: return false
	
	# an invincible player obviously also cannot be sliced
	# TO DO: might give issues when someone isn't sliced at first, yet then becomes vincible again while knife is inside??
	if is_player and obj.modules.specialstatus.invincibility.is_invincible: 
		particles.general_feedback(body.global_position, "Invincible!")
		return false
	
	# if the object has the same (team) owner as the throwable, never slice
	if is_player and obj.modules.knives.is_mine(body): return false
	
	# if the object is also in the stuckables group, only make slicing succesful if speed high enough
	if obj.is_in_group("Stuckables") and not body.modules.mover.at_high_speed(): return false
	
	# if the distance traveled was too low, tell player that, do nothing
	# (only applicable to players, as using it on powerups/environment as well would just be annoying)
	var dist_traveled = body.modules.distancetracker.calculate()
	if is_player and GlobalDict.cfg.deflect_knives_if_too_close:
		if dist_traveled < MIN_DIST_BEFORE_SLICE:
			particles.general_feedback(body.global_position, "Too close!")
			return false
		
		elif dist_traveled < MIN_DIST_BEFORE_CERTAIN_SLICE:
			var prob = (dist_traveled-MIN_DIST_BEFORE_SLICE)/(MIN_DIST_BEFORE_CERTAIN_SLICE - MIN_DIST_BEFORE_SLICE)
			if randf() > prob: 
				particles.general_feedback(body.global_position, "Too close!")
				return false
	
	# some powerups can repel knives
	var res = check_repellant_powerup(obj)
	if res: return false
	
	var normal = body.modules.mover.velocity.normalized()
	var center = body.global_position
	var start = center - normal * 500
	var end = center + normal * 500
	
	particles.create_slash(body.modules.fakebody.get_bottom_pos(), normal)
	
	# NOTE: slicing stuff changes a LOT of the physics and collisions
	# so make sure we invalidate any info afterwards
	body.modules.fakebody.reset_all()
	
	var hit_a_player = is_player
	var my_owner = body.modules.owner.get_owner()
	var result = slicer.slice_bodies_hitting_line(start, end, [], [obj], body)
	if result.size() <= 0: return false
	
	body.modules.fakebody.add_collision_exception(obj)
	for sliced_body in result:
		body.modules.fakebody.add_collision_exception(sliced_body)
	
	body.modules.status.record_succesful_action(1)
	
	if my_owner and hit_a_player:
		var penalty = mode.get_player_slicing_penalty()
		if penalty != 0: my_owner.modules.collector.collect(penalty)
		
		my_owner.modules.statistics.record("players_sliced", 1)
		
		if dist_traveled > MIN_DIST_LONG_THROW_BONUS:
			particles.general_feedback(body.global_position, "Long throw!")
			
			body.modules.mover.set_velocity(body.modules.distancetracker.get_original_velocity())
			
			my_owner.modules.grower.grow(0.2)
			
			var perform_extra_slice = (randf() <= LONG_THROW_EXTRA_SLICE_PROB)
			if perform_extra_slice: obj.modules.slasher.self_slice()

	return true

func deflect(res):
	var vel = body.modules.mover.velocity
	var going_too_slow = (vel.length() <= 0.1)
	if going_too_slow: return
	
	var too_soon = (OS.get_ticks_msec() - last_deflection_time) < MIN_TIME_BETWEEN_DEFLECTIONS
	if too_soon: return
	
	particles.create_explosion_particles(body.global_position)
	GlobalAudio.play_dynamic_sound(body, "thud")

	# now MIRROR the velocity
	var norm = res.normal
	var new_vel = -(2 * norm.dot(vel) * norm - vel)

	body.modules.fakebody.reset_collision_exceptions()
	body.modules.mover.set_velocity(VELOCITY_LEFT_AFTER_DEFLECTION*new_vel)
	
	last_deflection_time = OS.get_ticks_msec()
	
	var hit_body = res.collider
	if hit_body.script and hit_body.has_method("on_deflect"):
		hit_body.on_deflect(body)
