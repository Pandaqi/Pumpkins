extends Node2D

const EXPLODE_FORCE : float = 1000.0

export var wait_time : float = 15.0

onready var timer = $Timer
onready var body = get_parent()

onready var map = get_node("/root/Main/Map")

func _ready():
	timer.wait_time = wait_time
	timer.start()

func _on_Timer_timeout():
	throw_away_all_throwables_we_own()
	body.modules.status.delete()

func throw_away_all_throwables_we_own():
	for child in body.get_children():
		if child.is_in_group("Throwables"):
			child.modules.thrower.throw_from_object(self, EXPLODE_FORCE)

