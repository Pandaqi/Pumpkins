extends Node2D

onready var part : Particles2D = $Particles2D
onready var water_part : Particles2D = $WaterParticles

onready var body = get_parent()

var is_moving : bool = false

func disable():
	self.queue_free()

func update_team_num(num):
	part.texture = load("res://assets/ui/TeamIcon-" + str(num+1) + ".png")

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
