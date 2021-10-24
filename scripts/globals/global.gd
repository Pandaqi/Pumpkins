extends Node

var scenes = {
	"GameConfig": preload("res://GameConfig.tscn"),
	"Settings": preload("res://Settings.tscn"),
	"Main": preload("res://Main.tscn"),
}

var first_round : bool = true
var is_restart : bool = false

func is_poki_build():
	return (OS.get_name() == "HTML5")

func start_game():
	GlobalDict.update_from_current_config()
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(scenes.Main)
	
	is_restart = false
	
	if first_round:
		first_round = false

func restart():
	is_restart = true
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func load_settings():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(scenes.Settings)

func load_menu():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(scenes.GameConfig)
