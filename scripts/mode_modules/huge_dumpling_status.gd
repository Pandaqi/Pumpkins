extends Node

var team_num : int = -1
var player_num : int = -1

onready var body = get_parent()
onready var team_icon = get_node("../Drawer/Team")
onready var players = get_node("/root/Main/Players")

export var dumpling_part_color : Color = Color(1.0, 207/255.0, 112/255.0)

func set_team_num(num):
	team_num = num
	team_icon.set_frame(num)
	
	body.modules.drawer.set_color(dumpling_part_color)
	body.modules.drawer.use_huge_coloring()

func can_die():
	return true

func almost_dead():
	body.modules.animationplayer.play("DumplingFlickerBad")

# When we die, kill all players in our team
# This should automatically send a message to game over that each player died, thus checking for game over 
func die():
	var team = players.get_players_in_team(team_num)
	for player in team:
		
		# @param => forced = true, so nothing can get in the way
		player.modules.status.die(true)
	
	body.queue_free()
	
	print("HUGE DUMPLING DIED!")

# Wait, as we automatically reposition around zero, won't this just stay correct?
func _on_Shaper_shape_updated():
	team_icon.set_position(Vector2.ZERO)
	
	print(body.modules.shaper.area)
	
	var full_dumpling_area = 38000
	var new_scale = clamp(sqrt(body.modules.shaper.area) / sqrt(full_dumpling_area), 0.15, 1.0)
	team_icon.set_scale(Vector2(1,1)*new_scale)
	
	if new_scale <= 0.5:
		body.modules.drawer.use_regular_coloring()
