extends Node2D

var tile_scale : Vector2
var glow_scale : Vector2

var populator_node = null
var grid_pos : Vector2

var in_focus : bool = false

var hovered : bool = false
var focused_by_hover : bool = false

var val : bool = false

var section : String
var type : String
var single_choice_mode : bool = false

var reset_btn : bool = false
var random_btn : bool = false

onready var tween = $Tween

var grayscale_shader = preload("res://shaders/grayscale.tres")

func is_on():
	return val

func make_reset_button():
	set_sprite_to_default_buttons()
	reset_btn = true
	$Sprite.set_frame(1)
	$Hover.set_frame(1)
	$Glow.set_visible(false)

func make_random_button():
	set_sprite_to_default_buttons()
	random_btn = true
	$Sprite.set_frame(0)
	$Hover.set_frame(0)
	$Glow.set_visible(false)

func set_sprite_to_default_buttons():
	var sprite = get_node("Sprite")
	sprite.texture = load("res://assets/ui/settings/default_buttons.png")
	sprite.hframes = 2
	sprite.vframes = 1
	
	var hover = get_node("Hover")
	hover.texture = load("res://assets/ui/settings/default_buttons_hover.png")
	hover.hframes = 2
	hover.vframes = 1

func set_size(sc, glow_sc):
	tile_scale = sc
	glow_scale = glow_sc

func set_type(frame : int, tp : String, sec : String):
	type = tp
	section = sec
	$Hover.set_frame(frame)
	$Sprite.set_frame(frame)

func read_value_from_config():
	val = GlobalConfig.read_game_config(section, type)
	update_selection_ui()
	
	check_single_choice_mode()

func reset(turn_on):
	if reset_btn or random_btn: return
	if type == "tutorial_active": return
	
	if turn_on and not is_on(): toggle()
	elif not turn_on and is_on(): toggle()

func randomize_me():
	if reset_btn or random_btn: return
	if type == "tutorial_active": return
	
	if randf() <= 0.5: toggle()

func toggle():
	if reset_btn:
		populator_node.reset_all_options()
		return
	
	elif random_btn:
		populator_node.randomize_all_options()
		return
	
	val = not val
	update_selection_ui()

	GlobalConfig.update_game_config(section, type, val)
	
	check_single_choice_mode()

func check_single_choice_mode():
	if not single_choice_mode: return
	if not val: return
	
	# we are the ONLY correct option?
	# by default, set a "final_val" that I can easily access
	GlobalConfig.update_game_config(section, "final_val", type)

func update_selection_ui():
	if reset_btn or random_btn:
		modulate.a = 1.0
		$Sprite.material = null
		$Glow.set_visible(false)
		return
	
	if not val:
		modulate.a = 0.5
		$Sprite.material = grayscale_shader
		$Hover.material = grayscale_shader
	
	$Glow.set_scale(Vector2(1,1)*glow_scale)
	$Glow.set_visible(in_focus and val)
	
	if in_focus or val:
		modulate.a = 1.0
		$Sprite.material = null
		$Hover.material = null

func focus():
	in_focus = true
	hover()
	update_selection_ui()

func unfocus():
	in_focus = false
	unhover()
	update_selection_ui()

func hover():
	var target_scale = tile_scale*2.0
	
	tween.interpolate_property(self, "scale",
	get_scale(), target_scale, 0.33,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	z_index = 100
	hovered = true
	
	$Sprite.set_visible(false)
	$Hover.set_visible(true)
	
	GlobalAudio.play_static_sound("button")

func unhover():
	var target_scale = tile_scale
	
	tween.interpolate_property(self, "scale",
	get_scale(), target_scale, 0.33,
	Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()
	
	$Sprite.set_visible(true)
	$Hover.set_visible(false)
	
	z_index = 0
	hovered = false
