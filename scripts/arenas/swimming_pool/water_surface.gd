extends Sprite

const RESET_THRESHOLD : float = 0.996 # closer to 1 means a longer wait between waves

const NUM_WAVES_UNTIL_DIR_CHANGE : int = 5

onready var area = $Area2D
onready var water_line = $WaterLine

export var water_strength : float = 600.0
export var water_dir : Vector2 = Vector2.DOWN

var cur_water_line : float = 0.0
var water_line_exceptions : Array = []

var num_waves_passed : int = 0

var vp = Vector2(1920,1080)

func _ready():
	change_direction()

func _physics_process(dt):
	move_water_line(dt)
	constant_push_rigid_bodies(dt)

func constant_push_rigid_bodies(dt):
	for b in area.get_overlapping_bodies():
		if not (b is RigidBody2D): continue
		
		if b.get_linear_velocity().length() < 20:
			b.apply_central_impulse(water_dir)

func move_water_line(dt):
	cur_water_line = lerp(cur_water_line, 1.0, dt);
	if cur_water_line >= RESET_THRESHOLD:
		reset_water_line()
	
	# behind the scenes, we just keep going from 0 to 1
	# but visually, we reverse it if we're going in reverse direction
	var visual_water_line = cur_water_line
	if water_dir.x < 0 or water_dir.y < 0:
		visual_water_line = 1.0 - cur_water_line
	
	var ortho = water_dir.rotated(0.5*PI)
	ortho.x = abs(ortho.x)
	ortho.y = abs(ortho.y)
	
	var abs_water_dir = water_dir
	water_dir.x = abs(water_dir.x)
	water_dir.y = abs(water_dir.y)
	
	var line_offset = 0.5 * vp * ortho
	var actual_line = visual_water_line * abs_water_dir * vp
	var new_pos = line_offset + actual_line
	water_line.set_position(new_pos)
	
	# NOTE: still no fucking clue why I have to add 0.5*PI to this?
	water_line.set_rotation(water_dir.angle() + 0.5*PI)

	material.set_shader_param("cur_line", visual_water_line)

func change_direction():
	# ensure it changes to something different
	var rand_index = randi() % 3 + 1
	water_dir = water_dir.rotated(rand_index * 0.5*PI)
	
	material.set_shader_param("water_dir", water_dir)
	
	num_waves_passed = 0

func reset_water_line():
	cur_water_line = 0.0
	water_line_exceptions = []
	
	num_waves_passed += 1
	if num_waves_passed >= NUM_WAVES_UNTIL_DIR_CHANGE:
		change_direction()

func _on_Area2D_body_entered(body):
	body.modules.status.enter_water()

func _on_Area2D_body_exited(body):
	body.modules.status.exit_water()

func _on_WaterLine_body_entered(body):
	if not body.modules.status.in_water: return
	if body in water_line_exceptions: return
	
	if not body.modules.status.react_to_areas(): return
	
	var rand_dir = water_dir.rotated((randf() - 0.5)*0.2*PI)
	var force = rand_dir * water_strength
	if body is KinematicBody2D:
		body.modules.knockback.apply(force)
		water_line_exceptions.append(body)
	
	elif body is RigidBody2D:
		body.apply_central_impulse(0.1*force)
		water_line_exceptions.append(body)
