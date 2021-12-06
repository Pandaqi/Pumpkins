extends KinematicBody2D

const KNOCKBACK_FORCE : float = 3500.0
const SPEED : float = 300.0
const ROTATE_SPEED : float = 20.0

var move_dir : Vector2 = Vector2.ZERO

func set_direction(dir):
	move_dir = dir

func _physics_process(dt):
	rotate(ROTATE_SPEED * dt)
	var collision = move_and_collide(move_dir*SPEED*dt)
	
	if not collision: return
	
	var hit_body = collision.collider
	if not hit_body.is_in_group("Players"): return
	
	var force = -collision.normal * KNOCKBACK_FORCE
	hit_body.modules.knockback.apply(force)
