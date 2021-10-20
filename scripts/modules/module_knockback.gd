extends Node

const DAMPING : float = 0.925

var knockback_force : Vector2 = Vector2.ZERO
onready var body = get_parent()

func _physics_process(_dt):
	check_force()

func apply(force):
	knockback_force = force

func check_force():
	if knockback_force.length() <= 0.03: return

	body.move_and_slide(knockback_force)
	knockback_force *= DAMPING
	
	if knockback_force.length() <= 4.0:
		knockback_force = Vector2.ZERO
		return
	
	
