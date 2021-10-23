extends Node

onready var main = get_parent()

func _input(ev):
	check_new_controller(ev)
	check_new_keyboard(ev)
	
	check_remove_controller(ev)
	check_remove_keyboard(ev)
	check_remove_bot(ev)
	
	check_team_change(ev)
	
	check_navigation(ev)

func check_navigation(ev):
	if ev.is_action_released("continue"):
		GlobalAudio.play_static_sound("ui_button_press")
		start_game()
	
	elif ev.is_action_released("open_settings"):
		GlobalAudio.play_static_sound("ui_button_press")
		open_settings()
	
	elif ev.is_action_released("game_quit"):
		GlobalAudio.play_static_sound("ui_button_press")
		exit()

func start_game():
	main.save_configuration()
	
	if main.count_total_players() <= 1:
		print("Can't play solo!")
		return
	
	Global.start_game()

func open_settings():
	Global.load_settings()

func exit():
	get_tree().quit()

func check_team_change(ev):
	# keyboard players
	for i in range(4):
		var id = -(i+1)
		if ev.is_action_released("left_" + str(id)):
			GlobalAudio.play_static_sound("ui_team_change")
			main.change_team(GlobalInput.get_player_num_from_device_id(id))
			return
	
	# controllers
	if ev is InputEventJoypadButton:
		if ev.button_index == 2 and not ev.pressed:
			GlobalAudio.play_static_sound("ui_team_change")
			main.change_team(GlobalInput.get_player_num_from_device_id(ev.device))

func check_new_controller(ev):
	if not (ev is InputEventJoypadButton): return
	if ev.pressed: return
	if GlobalInput.device_already_registered(ev.device): return
	
	if ev.is_action_released("add_bot"):
		main.add_bot()
	else:
		GlobalInput.add_new_player('controller', ev.device)
	
	GlobalAudio.play_static_sound("ui_player_add")
	main.update_interface()

func check_remove_controller(ev):
	if not (ev is InputEventJoypadButton): return
	if ev.pressed: return
	
	if not GlobalInput.device_already_registered(ev.device): return
	if ev.button_index != 1: return
	
	GlobalAudio.play_static_sound("ui_player_remove")
	main.player_removed(GlobalInput.remove_player('controller', ev.device))

func check_new_keyboard(ev): 
	if not ev.is_action_released("add_keyboard_player"): return
	
	if ev.is_action_released("add_bot"):
		main.add_bot()
	else:
		GlobalInput.add_new_player('keyboard')
	
	GlobalAudio.play_static_sound("ui_player_add")
	main.update_interface()

func check_remove_keyboard(ev):
	if not ev.is_action_released("remove_keyboard_player"): return
	
	GlobalAudio.play_static_sound("ui_player_remove")
	main.player_removed(GlobalInput.remove_player('keyboard'))

func check_remove_bot(ev):
	if not ev.is_action_released("remove_bot"): return
	
	GlobalAudio.play_static_sound("ui_player_remove")
	main.remove_bot()
