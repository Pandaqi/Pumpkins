extends Node

var scenes = {
	"GameConfig": preload("res://GameConfig.tscn"),
	"Settings": preload("res://Settings.tscn"),
	"Main": preload("res://Main.tscn"),
}

var first_round : bool = true

func is_poki_build():
	return (OS.get_name() == "HTML5")

func start_game():
	GlobalDict.update_from_current_config()
	get_tree().change_scene_to(scenes.Main)

func load_settings():
	get_tree().change_scene_to(scenes.Settings)

func load_menu():
	get_tree().change_scene_to(scenes.GameConfig)
