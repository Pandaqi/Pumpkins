extends CanvasLayer

onready var cont = $Control/CenterContainer/VBoxContainer
onready var main_node = get_parent()

var setting_module_scene = preload("res://scenes/settings_module.tscn")
var modules = []

var active : bool = false

func _ready():
	create_interface()
	hide()

func hide():
	$Control.set_visible(false)
	get_tree().paused = false
	active = false
	
	for mod in modules:
		mod.release_focus()

func show():
	get_tree().paused = true
	
	$Control.set_visible(true)
	grab_focus_on_first()
	active = true

func _unhandled_input(ev):
	if ev.is_action_released("open_technical_settings"):
		GlobalAudio.play_static_sound("ui_button_press")
		
		if active:
			hide()
		else:
			show()

func grab_focus_on_first():
	modules[0].grab_focus_on_comp()

func create_interface():
	var st = GlobalConfig.settings
	
	for i in range(st.size()):
		var cur_setting = st[i]
		var node = setting_module_scene.instance()
		
		if Global.is_poki_build() and cur_setting.name == "Fullscreen":
			continue
		
		# set correct name and section,
		# so it knows WHICH entries to update
		node.initialize(cur_setting)
		
		# set to the current saved value in the config
		node.update_to_config()
		
		# add the whole thing
		cont.add_child(node)
		modules.append(node)
	
	# make sure the back button is at the BOTTOM
	var back_btn = cont.get_node("Back")
	cont.remove_child(back_btn)
	cont.add_child(back_btn)

func _on_Back_pressed():
	GlobalAudio.play_static_sound("ui_button_press")
	
	self.hide()
	main_node.show()
