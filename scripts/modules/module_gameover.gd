extends Node2D

onready var gui = get_node("/root/Main/GUI")
onready var my_gui = get_node("Container")
onready var instruc_gui = get_node("Container2")
var gui_size = 256*0.35

const FLIPPED_CONTENT_OFFSET = 54

onready var body = get_parent()

func _ready():
	hand_to_gui()
	disable()

func hand_to_gui():
	remove_child(my_gui)
	gui.add_child(my_gui)
	
	remove_child(instruc_gui)
	gui.add_child(instruc_gui)

func disable():
	my_gui.set_visible(false)
	instruc_gui.set_visible(false)

func enable(winner : bool = false):
	my_gui.set_scale(Vector2.ZERO)
	my_gui.set_visible(true)
	
	if winner:
		my_gui.get_node("Labels").set_visible(false)
	
	var target_frame = 3
	if winner: target_frame = 2
	
	my_gui.get_node("Sprite").set_frame(target_frame)
	
	gui.tween_appearance(my_gui)

func add_instructions():
	instruc_gui.set_scale(Vector2.ZERO)
	instruc_gui.set_visible(true)
	instruc_gui.get_node("Sprite").set_frame(1)
	instruc_gui.get_node("Labels").set_visible(false)
	
	gui.tween_appearance(instruc_gui)

func remove_instructions():
	instruc_gui.queue_free()
	instruc_gui = null

func determine_offset_vec():
	var pos = body.get_global_position()
	var vec = Vector2(1,1)
	if pos.x >= 0.5*1920:
		vec.x = -1
	if pos.y >= 0.5*1080:
		vec.y = -1
	
	return vec

func _physics_process(_dt):
	if not my_gui.is_visible(): return
	
	var vec = determine_offset_vec()
	position_gui(my_gui, vec)
	
	vec.x *= -1
	position_gui(instruc_gui, vec)

func position_gui(obj, offset_vec):
	if not obj: return
	
	var pos = body.get_global_transform_with_canvas().origin
	var offset = (gui_size + 14)
	
	obj.set_position(pos + offset_vec*offset)
	
	obj.get_node("BG").flip_h = (offset_vec.x < 0)
	obj.get_node("BG").flip_v = (offset_vec.y > 0)
	
	obj.get_node("Sprite").position.y = 0
	if obj.has_node("Labels"): obj.get_node("Labels").position.y = 0
	
	if obj.get_node("BG").flip_v:
		obj.get_node("Sprite").position.y = FLIPPED_CONTENT_OFFSET
		if obj.has_node("Labels"): 
			obj.get_node("Labels").position.y = FLIPPED_CONTENT_OFFSET
