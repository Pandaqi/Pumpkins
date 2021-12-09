extends Node2D

var MAX_SLIDES : int = 3

onready var gui = get_node("/root/Main/GUI")
onready var my_gui = $Node2D
onready var body = get_parent()

var player_num : int
var cur_slide = -1

var is_active : bool = false

var amount_moved : float = 0.0
var num_slashes : int = 0
var num_frames_aimed : int = 0

func activate(num):
	is_active = true
	if GlobalDict.cfg.use_control_scheme_with_constant_moving:
		MAX_SLIDES = 2
	
	remove_child(my_gui)
	gui.add_child(my_gui)
	
	player_num = num
	load_next_slide()

func self_destruct():
	is_active = false
	if my_gui: my_gui.queue_free()
	self.queue_free()
	if body and body.modules:
		body.modules.erase('tutorial')

func get_frame_offset():
	var id = GlobalInput.get_device_id(player_num)
	if id < 0:
		return abs(id)
	else:
		 return 0

func load_next_slide():
	cur_slide += 1
	if cur_slide >= MAX_SLIDES:
		self_destruct()
		return
	
	my_gui.set_scale(Vector2.ZERO)
	my_gui.get_node("Sprite").set_frame(cur_slide*5 + get_frame_offset())
	gui.tween_appearance(my_gui, false)

func _physics_process(_dt):
	var vec = body.modules.gameover.determine_offset_vec()
	body.modules.gameover.position_gui(my_gui, vec)

func _on_Mover_moved(amount):
	amount_moved += amount.length()
	
	if cur_slide == 0 and amount_moved > 500.0:
		load_next_slide()

func _on_Slasher_quick_slash():
	num_slashes += 1
	
	if cur_slide == 1 and num_slashes >= 3:
		load_next_slide()
	
func _on_Slasher_thrown_slash():
	num_slashes += 1
	
	if cur_slide == 1 and num_slashes >= 3:
		load_next_slide()

func _on_Slasher_aim():
	num_frames_aimed += 1
	
	if cur_slide == 2 and num_frames_aimed >= 240:
		load_next_slide()
