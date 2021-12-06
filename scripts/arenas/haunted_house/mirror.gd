extends StaticBody2D

onready var timer = $Timer
onready var modules = {
	'status': $Status,
	'drawer': $Drawer
}

func _ready():
	set_random_functionality()

func set_random_functionality():
	if randf() <= 0.5:
		make_deflecting()
	else:
		make_breaking()

func make_deflecting():
	add_to_group("Deflectables")

func make_breaking():
	add_to_group("Sliceables")

func on_deflect(throwable):
	var players = get_tree().get_nodes_in_group("Players")
	players.erase(throwable.modules.owner.get_owner())
	players.shuffle()
	throwable.modules.owner.set_owner(players[0])

func on_slice(throwable):
	timer.start()

func _on_Timer_timeout():
	get_parent().queue_free()
