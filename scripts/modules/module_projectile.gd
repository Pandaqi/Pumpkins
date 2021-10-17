extends Node2D

onready var body = get_parent()

onready var slicer = get_node("/root/Main/Slicer")

var ignore_deflections : bool = false
var extra_collision_exceptions = []

var being_held : bool = false

func _integrate_forces(state):
	if being_held: return
	
	ignore_deflections = false
	
	var num_contacts = state.get_contact_count()
	for i in range(num_contacts):
		var res = slice_through_body(state, i)
		if res: 
			ignore_deflections = true
			break
	
	if not ignore_deflections:
		for i in range(num_contacts):
			body.modules.deflector.check_deflections(state, i)

	body.set_rotation(state.linear_velocity.angle())

func slice_through_body(state, index):
	var obj = state.get_contact_collider_object(index)
	if not obj.is_in_group("Players"): return false
	
	var rot = body.last_rotation
	var normal = Vector2(cos(rot), sin(rot))
	
	var center = body.get_global_position()
	var start = center - normal * 500
	var end = center + normal * 500

	var result = slicer.slice_bodies_hitting_line(start, end, [body], [obj])
	if result.size() <= 0: return false
	
	body.add_collision_exception_with(obj)
	extra_collision_exceptions.append(obj)
	
	for sliced_body in result:
		body.add_collision_exception_with(sliced_body)
		extra_collision_exceptions.append(sliced_body)
	
	body.reset_velocity_to_last_point(state)

	return true

func _on_Deflector_deflected():
	reset_collision_exceptions()

func reset_collision_exceptions():
	for obj in extra_collision_exceptions:
		if not obj or not is_instance_valid(obj): continue
		body.remove_collision_exception_with(obj)
	
	extra_collision_exceptions = []

func _on_Area2D_body_entered(other_body):
	if not other_body.is_in_group("Players"): return
	if not other_body.modules.has("knives"): return
	if not other_body.modules.knives.is_mine(body): return

	other_body.modules.knives.plan_knife_grab(body)

func _on_Area2D_body_exited(other_body):
	pass # Replace with function body.
