extends StaticBody2D

const MOVE_SPEED : float = 75.0

func on_move_vec(vec, dt):
	set_position(get_position() + vec*dt*MOVE_SPEED)

func on_throw():
	var bodies = $Area2D.get_overlapping_bodies()
	for b in bodies:
		var vec_away = (b.global_position - global_position).normalized()
		
		if not b.is_in_group("Throwables"): continue
		b.set_velocity(vec_away * 1000.0)
