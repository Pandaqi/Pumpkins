extends Node2D

onready var gui = get_node("/root/Main/GUI")
onready var my_gui = get_node("Sprite")
var instruc_gui = null
var gui_size = 256*0.5

onready var body = get_parent()

func _ready():
	hand_to_gui()
	disable()

func hand_to_gui():
	remove_child(my_gui)
	gui.add_child(my_gui)

func disable():
	my_gui.set_visible(false)

func enable(winner : bool = false):
	my_gui.set_visible(true)
	
	var target_frame = 2
	if winner: target_frame = 1
	
	my_gui.set_frame(target_frame)

func add_instructions():
	instruc_gui = my_gui.duplicate()
	instruc_gui.set_visible(true)
	instruc_gui.set_frame(0)

func _physics_process(dt):
	if not my_gui.is_visible(): return
	
	var pos = body.get_global_transform_with_canvas().origin
	var offset = (gui_size + 50)
	
	my_gui.set_position(pos + Vector2(1,1)*offset)
	
	if instruc_gui:
		instruc_gui.set_position(pos + Vector2(-1,1)*offset)
