extends Node2D

onready var part : Particles2D = $Particles2D
onready var water_part : Particles2D = $WaterParticles
onready var stun_particles = $StunParticles
onready var invincibility_particles = $InvincibilityParticles

onready var particles = get_node("/root/Main/Particles")

onready var body = get_parent()

var is_moving : bool = false

var last_continuous_feedback : float = -1
const CONTINUOUS_FEEDBACK_THRESHOLD : float = 750.0

func _ready():
	on_stun_end()
	on_invincibility_end()
	_on_Mover_movement_stopped()

func disable():
	self.queue_free()

func update_team_num(num):
	var texture_key = "res://assets/ui/TeamIcon-" + str(num+1) + ".png"
	part.texture = load(texture_key)

# NOTE: Don't use "set_visible(true/false)" as that immediately hides all particles, even those that were still happening
# NOTE: Simply use "set_emitting(true/false)" to prevent NEW ones from spawning, but keep the old ones happening
func _on_Mover_movement_started():
	is_moving = true
	
	part.set_emitting(true)
	
	if body.modules.status.in_water: 
		water_part.set_emitting(true)

func enter_water():
	water_part.set_emitting(true)

func exit_water():
	water_part.set_emitting(false)

func _on_Mover_movement_stopped():
	is_moving = false
	
	part.set_emitting(false)
	water_part.set_emitting(false)

func continuous_feedback(txt):
	var diff = OS.get_ticks_msec() - last_continuous_feedback
	if diff < CONTINUOUS_FEEDBACK_THRESHOLD: return
	
	particles.general_feedback(body.global_position, txt)
	last_continuous_feedback = OS.get_ticks_msec()

func on_stun_start():
	stun_particles.set_emitting(true)

func on_stun_end():
	stun_particles.set_emitting(false)

func on_invincibility_start():
	invincibility_particles.set_emitting(true)

func on_invincibility_end():
	invincibility_particles.set_emitting(false)
