extends CanvasLayer

onready var main = get_parent()
onready var game_state = get_node("../GameState")
onready var tween = $Tween
var active : bool = false
var bg_alpha : float = 0.8

func _ready():
	hide(true)

func _input(ev):
	if tween.is_active(): return
	if not main.game_officially_started: return
	if game_state.game_over_state: return
	
	if not active:
		if ev.is_action_released("pause_open"):
			show()
	
	else:
		if ev.is_action_released("pause_restart"):
			get_tree().paused = false
			Global.restart()
		
		elif ev.is_action_released("pause_continue"):
			hide()
		
		elif ev.is_action_released("pause_exit"):
			get_tree().paused = false
			Global.load_menu()

func hide(immediate = false):
	if immediate:
		end_pause_mode()
	
	else:
		play_disappearance_tween($Buttons/Restart)
		play_disappearance_tween($Buttons/Continue, 0.3)
		play_disappearance_tween($Buttons/Exit, 0.6)
		fade_out_tween($ColorRect)
		
		GlobalAudio.play_static_sound("ui_button_press")

func start_pause_mode():
	active = true

func end_pause_mode():
	$ColorRect.set_visible(false)
	$Buttons.set_visible(false)
	
	get_tree().paused = false
	active = false

func show():
	GlobalAudio.play_static_sound("ui_button_press")
	
	$Buttons.set_visible(true)
	$ColorRect.set_visible(true)
	
	play_appearance_tween($Buttons/Restart)
	play_appearance_tween($Buttons/Continue, 0.3)
	play_appearance_tween($Buttons/Exit, 0.6)
	fade_in_tween($ColorRect)
	
	get_tree().paused = true

func play_appearance_tween(p, delay : float = 0.0):
	var duration = 0.5
	var base_scale = 0.5
	
	p.set_scale(Vector2.ZERO)
	tween.interpolate_property(p, "scale", 
		Vector2.ZERO, Vector2(1,1)*base_scale, 2*duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT,
		delay)
	
	tween.interpolate_property(p, "rotation", 
		0, 2*PI, duration,
		Tween.TRANS_ELASTIC, Tween.EASE_OUT,
		delay)
	
	tween.start()

func play_disappearance_tween(p, delay : float = 0.0):
	var duration = 0.5
	var base_scale = 0.5
	
	tween.interpolate_property(p, "scale", 
		Vector2(1,1)*base_scale, Vector2.ZERO, duration,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		delay)
	
	tween.interpolate_property(p, "rotation", 
		0, 2*PI, duration,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		delay)
	
	tween.start()

func fade_in_tween(p):
	tween.interpolate_property(p, "color",
		Color(0,0,0,0.0), Color(0,0,0,bg_alpha), 0.6,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func fade_out_tween(p):
	tween.interpolate_property(p, "color",
		Color(0,0,0,bg_alpha), Color(0,0,0,0.0), 0.6,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func _on_Tween_tween_all_completed():
	if not active:
		start_pause_mode()
	else:
		end_pause_mode()
