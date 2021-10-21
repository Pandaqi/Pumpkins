extends Node2D

func _ready():
	$ForwardButtons.material = $ForwardButtons.material.duplicate(true)
