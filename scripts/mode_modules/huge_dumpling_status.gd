extends Node

var team_num : int = -1

onready var body = get_parent()
onready var players = get_node("/root/Main/Players")

func set_team_num(num):
	team_num = num
	$Team.set_frame(num)

func can_die():
	return true

# When we die, kill all players in our team
# This should automatically send a message to game over that each player died, thus checking for game over 
func die():
	var team = players.get_players_in_team(team_num)
	for player in team:
		player.modules.status.die()
	
	body.queue_free()

# Wait, as we reposition around zero, won't this just stay correct?
func _on_Shaper_shape_updated():
	$Team.set_position(Vector2.ZERO)
