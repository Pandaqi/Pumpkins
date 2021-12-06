extends Node2D

onready var teleport_timer = $TeleportTimer
onready var body = get_parent()
onready var particles = get_node("/root/Main/Particles")

var forced_teleport_allowed : bool = true

func forced_allowed():
	return forced_teleport_allowed and teleport_timer.time_left <= 0

func teleport(pos):
	body.set_position(pos)
	
	teleport_timer.start()
	forced_teleport_allowed = false
	
	particles.general_feedback(body.global_position, "Teleport!")

# NOTE: we use "set_deferred" to ensure this triggers AFTER the "body_enter" signal on the other teleport
# (as this variable will now only reset at the END of this frame)
# Neat trick, works well, should use it more often.
func reset_teleport():
	set_deferred("forced_teleport_allowed", true)
