extends Node2D

const LINEAR_DAMPING : float = 0.999

onready var body = get_parent()
onready var timer = $Timer

onready var slicer = get_node("/root/Main/Slicer")

var ignore_deflections : bool = false
var collision_exceptions = []

var being_held : bool = false
var my_owner = null # NOTE "owner" is a registered word with Godot, so use something else

var velocity : Vector2 = Vector2.ZERO
var area_disabled : bool = false

func set_owner(o):
	my_owner = o

func has_no_owner():
	return (my_owner == null)

func set_velocity(vel):
	velocity = vel

func throw(vel):
	velocity = vel
	disable_area()

func _physics_process(dt):
	if being_held: return
	
	move(dt)
	shoot_raycast()

func move(dt):
	if velocity.length() <= 0.05:
		velocity = Vector2.ZERO
		return
	
	body.set_position(body.get_position() + velocity * dt)
	body.set_rotation(velocity.angle())
	
	velocity *= LINEAR_DAMPING

func shoot_raycast():
	var space_state = get_world_2d().direct_space_state
	
	var normal = velocity.normalized()
	var start = body.get_global_position()
	var end = start + normal * 50
	
	clean_up_collision_exceptions()
	
	var exclude = collision_exceptions + [my_owner]
	var collision_layer = 1 + 8 # layer 1 (all; 2^0) and 4 (powerups; 2^3)
	
	var result = space_state.intersect_ray(start, end, exclude, collision_layer)
	if not result: return

	var hit_body = result.collider
	if hit_body.is_in_group("Sliceables"):
		slice_through_body(result.collider)
	elif hit_body.is_in_group("Stuckables"):
		get_stuck(result)
	else:
		deflect(result)

func get_stuck(result):
	var dist_to_hit = (result.position - self.get_global_position()).length()
	if dist_to_hit > 10: return
	
	my_owner = null
	velocity = Vector2.ZERO

func slice_through_body(obj):
	var normal = velocity.normalized()
	var center = body.get_global_position()
	var start = center - normal * 500
	var end = center + normal * 500

	var result = slicer.slice_bodies_hitting_line(start, end, [], [obj])
	if result.size() <= 0: return false

	collision_exceptions.append(obj)
	
	for sliced_body in result:
		collision_exceptions.append(sliced_body)

	return true

func deflect(res):
	if velocity.length() <= 0.1: return

	# now MIRROR the velocity
	var norm = res.normal
	var new_vel = -(2 * norm.dot(velocity) * norm - velocity)

	velocity = new_vel
	reset_collision_exceptions()

func reset_collision_exceptions():
	collision_exceptions = []

func clean_up_collision_exceptions():
	for i in range(collision_exceptions.size()-1,-1,-1):
		var obj = collision_exceptions[i]
		if not obj or not is_instance_valid(obj):
			collision_exceptions.remove(i)

func disable_area():
	area_disabled = true
	timer.start()

func enable_area():
	area_disabled = false

func _on_Timer_timeout():
	enable_area()

func _on_Area2D_body_entered(other_body):
	if being_held: return
	if area_disabled: return
	
	if not other_body.is_in_group("Players"): return
	if not other_body.modules.has("knives"): return
	if not other_body.modules.knives.is_mine(body): return

	other_body.modules.knives.grab_knife(body)

func _on_Area2D_body_exited(other_body):
	pass # Replace with function body.



