extends Node2D

var player_num : int = -1

# Do not actually delete ourselves here, 
# as deleting goes on a timer (using the main script)
func delete(attacking_throwable):
	get_node("../Sprite").set_visible(false)
