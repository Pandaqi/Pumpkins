extends Area2D

export var water_strength : float = 600.0
export var water_dir : Vector2 = Vector2.DOWN

onready var mode = get_node("/root/Main/ModeManager")

func _physics_process(dt):
	constant_push_rigid_bodies(dt)

func constant_push_rigid_bodies(_dt):
	var screen_center = 0.5*Vector2(1920,1080)
	for b in get_overlapping_bodies():
		if not (b is RigidBody2D): continue
		
		var temp_water_dir = (b.global_position - screen_center).normalized().rotated(0.5*PI)
		if b.get_linear_velocity().length() < 20:
			b.apply_central_impulse(temp_water_dir)
			b.apply_torque_impulse(1)

func _on_Water_body_entered(body):
	if not body.modules.status.has_method("enter_water"): return
	body.modules.status.enter_water()

func _on_Water_body_exited(body):
	if not body.modules.status.has_method("enter_water"): return
	body.modules.status.exit_water()
