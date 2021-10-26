extends CanvasLayer

onready var anim_player = $AnimationPlayer
onready var label = $Label/Label

onready var mode = $PlayReminders/Mode
onready var arena = $PlayReminders/Arena

onready var main = get_parent()

var original_bus_index
var original_volume : float

var active : bool = false
var skipped : bool = false

func _input(ev):
	if not active: return
	if not ev.is_action_pressed("skip_reminders"): return
	
	skip()

# skip animation to the part AFTER the reminders
# (though not completely, as that is jarring and misses some of the other fade in
func skip():
	if skipped: return
	
	skipped = true
	$AnimationPlayer.seek(6.0, true)

func play_game_sound():
	GlobalAudio.play_static_sound("game_start")

func activate():
	get_tree().paused = true
	label.set_text("Go!")
	$Winners.set_visible(false)
	anim_player.play("FadeIn")
	
	mode.set_frame(GlobalDict.modes[GlobalDict.cfg.game_mode].frame)
	arena.set_frame(GlobalDict.arenas[GlobalDict.cfg.arena].frame)
	
	active = true
	
	if Global.is_restart: skip()

func unpause():
	get_tree().paused = false

func game_over(winning_team):
	$ColorRect.set_visible(true)
	$Label.set_visible(true)
	$Winners.set_visible(true)
	$Winners/Sprite.set_frame(winning_team)
	
	label.set_text("Game Over!")
	anim_player.play("TextFlash")
	
	get_tree().paused = true
	
	original_bus_index = AudioServer.get_bus_index("BG")
	original_volume = AudioServer.get_bus_volume_db(original_bus_index)
	AudioServer.set_bus_volume_db(original_bus_index, 0)
	
	active = true

func deactivate():
	$ColorRect.set_visible(false)
	$Label.set_visible(false)
	$Winners.set_visible(false)
	active = false
	
	main.start_game()

func self_destruct():
	AudioServer.set_bus_volume_db(original_bus_index, original_volume)
	get_tree().paused = false
	active = false
	self.queue_free()
