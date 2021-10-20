extends Node2D

onready var part : Particles2D = $Particles2D

func update_team_num(num):
	part.texture = load("res://assets/ui/TeamIcon-" + str(num+1) + ".png")

func _on_Mover_movement_started():
	part.set_emitting(true)

func _on_Mover_movement_stopped():
	part.set_emitting(false)
