extends Node2D

const GHOST_RAND_ROTATION : float = 0.05
const GHOST_SLOWDOWN : float = 0.995

const VELOCITY_LEFT_AFTER_DEFLECTION : float = 0.9
const MIN_TIME_BETWEEN_DEFLECTIONS : float = 50.0 # milliseconds

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
		if handled: body.queue_free()
		return
	
	if handled: return
	
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
	
	var hit_body = result.collider
	if not hit_body or not is_instance_valid(hit_body): return
	body.modules.grabber.try_grabbing(hit_body)

# TO DO: Not doing anything special with _ghosts_ anymore, as it doesn't seem worth it?
func poll_special_hits():
	for nonsolid in body.modules.fakebody.nonsolids_hit:
		if nonsolid.script and nonsolid.has_method("on_throwable_hit"):
			nonsolid.on_throwable_hit()

#
# Calculating the interactions we have
#

# TO DO: Check if the attacking object (ourselves, "body") is an actual knife?
func handle_dumpling(obj):
	var victim = obj.modules.owner.get_owner()
	var attacker = body.modules.owner.get_owner()
	victim.modules.knives.check_dumpling_hit(obj, attacker)

func get_stuck(result):
	if body.modules.status.is_stuck: return true
	if body.modules.status.type == "boomerang": return false
	
	body.modules.mover.set_velocity(Vector2.ZERO)
	body.set_position(result.position)
	body.set_rotation(-result.normal.angle())
	
	body.modules.status.reset_to_stuck_state()
	
	GlobalAudio.play_dynamic_sound(body, "thud")
	particles.create_explosion_particles(body.global_position)
	
	body.modules.fakebody.reset_all()
	body.modules.fakebody.reset_collision_exceptions()
	
	return true

func check_repellant_powerup(obj):
	if not obj.is_in_group("Players"): return false
	if not obj.modules.powerups.repel_knives: return false
	return true

func slice_through_body(obj):
	# projectiles with a real body can NEVER slice something
	if body.modules.fakebody.has_real_body: return false
	
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
	
	var my_owner = body.modules.owner.get_owner()
	var result = slicer.slice_bodies_hitting_line(start, end, [], [obj], my_owner)
	if result.size() <= 0: return false
	
	body.modules.fakebody.add_collision_exception(obj)
	for sliced_body in result:
		body.modules.fakebody.add_collision_exception(sliced_body)
	
	body.modules.status.record_succesful_action(1)
	
	if my_owner:
		var penalty = mode.get_player_slicing_penalty()
		if penalty != 0: my_owner.modules.collector.collect(penalty)
		
		my_owner.modules.statistics.record("players_sliced", 1)

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

# Ghosts slow down moving knifes
func apply_ghost_effect(_ghost):
	# TO DO: use the ghost argument for something?? (remove underscore then)
	
	var vel = body.modules.mover.velocity
	vel *= GHOST_SLOWDOWN
	vel = vel.rotated((randf()-0.5)*GHOST_RAND_ROTATION)
	body.modules.mover.set_velocity(vel)
