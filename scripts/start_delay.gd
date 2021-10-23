extends CanvasLayer

func activate():
	GlobalAudio.play_static_sound("game_start")
	
	get_tree().paused = true

func unpause():
	get_tree().paused = false

func deactivate():
	queue_free()
