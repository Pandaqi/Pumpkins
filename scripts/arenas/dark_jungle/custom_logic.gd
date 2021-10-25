extends Node2D

var predefined_powerup_locations = [Vector2(1100, 1035), Vector2(800,400), Vector2(1250, 400)]

func _ready():
	GlobalDict.cfg.predefined_powerup_locations = predefined_powerup_locations
	GlobalDict.cfg.auto_slice_powerups = false

# Required function
func activate():
	pass

# Required function
func on_player_death(p):
	var fireflies = get_tree().get_nodes_in_group("Fireflies")
	if fireflies.size() <= 0: return { }
	
	fireflies.shuffle()
	fireflies[0].set_owner(p)
	
	return { }
