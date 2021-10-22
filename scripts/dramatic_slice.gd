extends CanvasLayer

const DURATION : float = 0.07

onready var timer = $Timer
onready var overlay_shader = $ColorRect

func _ready():
	overlay_shader.set_visible(false)

func execute():
	if GlobalDict.cfg.disable_flashing_effects: return
	
	get_tree().paused = true
	
	timer.wait_time = DURATION
	timer.start()
	
	overlay_shader.set_visible(true)

func done():
	get_tree().paused = false
	
	overlay_shader.set_visible(false)

func _on_Timer_timeout():
	done()
