extends Node2D

var screens = ["modes", "arenas", "powerups", "settings"]
var screen_nodes = []
var cur_screen = -1

var config_screen_scene = preload("res://scenes/gui/config_screen.tscn")

onready var tween = $Tween

func _ready():
	for i in range(screens.size()):
		var s = config_screen_scene.instance()
		s.type = screens[i]
		s.set_position(Vector2(1920 * i, 0))
		screen_nodes.append(s)
		add_child(s)
	
	advance_screen(+1)

func _input(ev):
	if ev.is_action_released("config_continue"):
		advance_screen(+1)
	
	elif ev.is_action_released("config_exit"):
		advance_screen(-1)

func advance_screen(ds):
	if cur_screen >= 0:
		screen_nodes[cur_screen].disable()
	
	cur_screen += ds
	
	# no more screens? start the game!
	if cur_screen >= screens.size():
		Global.load_menu()
		return
	
	# can't go back further? move to input selection
	if cur_screen < 0:
		Global.load_menu()
		return
	
	# swap screens
	var target_pos = Vector2(-cur_screen*1920,0)
	tween.interpolate_property(self, "position", 
		null, target_pos, 1.0,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	screen_nodes[cur_screen].enable()

func tween_is_busy():
	return $Tween.is_active()
