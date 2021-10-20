extends Node2D

onready var team = $Team
onready var label = $Label
onready var player_icon_container = $Container
onready var anim_player = $AnimationPlayer

var player_icons = []
var player_icon_size = 32
var player_icon_scene = preload("res://scenes/gui/player_icon_simple.tscn")

func update_team(num):
	team.set_frame(num)
	anim_player.play("Update")

func update_label(num):
	var nothing_changed = num == int(label.get_text())
	if nothing_changed: return
	
	label.set_text(str(num))
	anim_player.play("Update")

func update_players_in_team(players):
	var offset = -0.5*(players.size() - 1)*player_icon_size*Vector2.RIGHT
	
	for i in range(players.size()):
		var player_num = players[i].modules.status.player_num
		var ic = player_icon_scene.instance()
		ic.set_frame(16 + player_num)
		
		player_icon_container.add_child(ic)
		ic.set_position(offset + Vector2.RIGHT*i*player_icon_size)
		
	
