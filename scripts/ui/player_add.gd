extends Node2D

var cur_team : int = -2
var player_num : int = -2
var is_bot : bool = false

onready var bg = $BG
onready var team = $Team
onready var bot = $Bot
onready var extra_buttons = $ExtraButtons

var state : String = ""

func set_data(data):
	is_bot = data.bot
	cur_team = data.team

func get_data():
	return { 'team': cur_team, 'bot': is_bot, 'active': is_active() }

func is_active():
	return (state != "disabled")

func set_player_num(num):
	player_num = num
	cur_team = num
	is_bot = false
	
	update_bg()
	update_team_icon()
	update_bot_status()

func update_bg():
	var frame = 2 + player_num
	if player_num == -1:
		frame = 0
	elif player_num <= -2:
		frame = 1
	
	bg.set_frame(frame)

func update_bot_status():
	var frame = 0 if is_bot else 1
	bot.set_frame(frame)

func make_human():
	is_bot = false
	update_bot_status()

func make_bot():
	is_bot = true
	update_bot_status()
	
	$ExtraButtons/ChangeTeam.set_visible(false)
	$ExtraButtons/Leave.set_visible(false)

func update_team_icon():
	team.set_frame(cur_team)

func change_team():
	cur_team = (cur_team + 1) % 6
	update_team_icon()

func disable():
	bg.set_frame(1)
	bot.set_visible(false)
	team.set_visible(false)
	extra_buttons.set_visible(false)
	
	state = "disabled"

func open():
	bg.set_frame(0)
	
	state = "disabled"

func enable():
	update_bg()
	
	bg.set_visible(true)
	bot.set_visible(true)
	team.set_visible(true)
	extra_buttons.set_visible(true)
	
	state = "enabled"

func show_extra_buttons(type):
	if type == 'controller':
		$ExtraButtons/Leave.set_visible(true)
		$ExtraButtons/ChangeTeam.set_visible(true)
	
	elif type == 'keyboard':
		$ExtraButtons/Leave.set_visible(false)
		$ExtraButtons/ChangeTeam.set_visible(true)
		
		var frame = 2 + abs(GlobalInput.get_device_id(player_num))
		$ExtraButtons/ChangeTeam.set_frame(frame)
		
func show_keyboard_leave_button():
	$ExtraButtons/Leave.set_visible(true)
	$ExtraButtons/Leave.set_frame(2)

func show_bot_leave_button():
	$ExtraButtons/Leave.set_visible(true)
	$ExtraButtons/Leave.set_frame(7)
