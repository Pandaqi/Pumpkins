extends Node2D

const MAX_POWERUPS_TO_SHOW : int = 8
const MAX_SETTINGS_TO_SHOW : int = 8

const DIST_BETWEEN_SPRITES : float = 64.0

var powerup_sprite = preload("res://scenes/gui/powerup_sprite.tscn")
var setting_sprite = preload("res://scenes/gui/powerup_sprite.tscn")

func _ready():
	read_mode()
	read_arena()
	read_powerups()
	read_settings()

func read_mode():
	var val = GlobalConfig.read_game_config("modes", "final_val")
	var frame = 0
	
	if GlobalDict.modes.has(val):
		frame = GlobalDict.modes[val].frame
	
	$Modes.set_frame(frame)

func read_arena():
	var val = GlobalConfig.read_game_config("arenas", "final_val")
	var frame = 0
	
	if GlobalDict.arenas.has(val):
		frame = GlobalDict.arenas[val].frame
	
	$Arenas.set_frame(frame)

func read_powerups():
	var powerups_enabled = []
	for key in GlobalDict.powerups:
		var val = GlobalConfig.read_game_config("powerups", key)
		if not val: continue
		
		powerups_enabled.append(key)
	
	var num_powerups = min(powerups_enabled.size(), MAX_POWERUPS_TO_SHOW)
	for i in range(num_powerups):
		var s = powerup_sprite.instance()
		var frame = GlobalDict.powerups[ powerups_enabled[i] ].frame
		s.set_frame(frame)
		
		$PowerupContainer.add_child(s)
		s.set_position(Vector2.RIGHT*DIST_BETWEEN_SPRITES*i)
		
		var dir = 1 if (i % 2 == 0) else -1
		s.set_rotation(dir*0.04*PI)

func read_settings():
	var settings_enabled = []
	for key in GlobalDict.configurable_settings:
		var val = GlobalConfig.read_game_config("settings", key)
		if not val: continue
		
		settings_enabled.append(key)
	
	var num_settings = min(settings_enabled.size(), MAX_SETTINGS_TO_SHOW)
	for i in range(settings_enabled.size()):
		var s = setting_sprite.instance()
		var frame = GlobalDict.configurable_settings[ settings_enabled[i] ].frame
		s.set_frame(frame)
		
		$SettingContainer.add_child(s)
		s.set_position(Vector2.RIGHT*0.5*DIST_BETWEEN_SPRITES*i)
