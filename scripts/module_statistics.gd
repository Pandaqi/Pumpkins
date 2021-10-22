extends Node

onready var body = get_parent()

var start_time
var awards = {
	"players_sliced": 0,
	"knives_used": 0,
	"quick_stabs": 0,
	"long_throws": 0,
	"knives_succesful": 0,
	"succesful_attacks": 0, # congregator; don't record directly
	"total_distance": 0,
	"distance_traveled": 0, # congregator; don't record directly
	"powerups_opened": 0,
	"powerups_grabbed": 0,
	"accumulated_size": 0,
	"average_size": 0, # congregator; don't record directly
	
}

func _ready():
	start_time = OS.get_ticks_msec()

func record(stat_name, val):
	if not awards.has(stat_name): return
	awards[stat_name] += val

func read(stat_name):
	if not awards.has(stat_name): return null
	return awards[stat_name]

func finalize_awards():
	var time_played = (OS.get_ticks_msec() - start_time) / 1000.0
	
	# divide by 1000 to get it in "kilometers", otherwise number probably way too large
	awards.distance_traveled = awards.total_distance / 1000.0
	
	# this is a percentage, so multply by 100
	awards.succesful_attacks = awards.knives_succesful / float(awards.knives_used + 1.0) * 100
	
	# this is recorded once every SECOND, so divide by time_played (which is also in SECONDS)
	awards.average_size = awards.accumulated_size / float(time_played + 0.01)

func set_award(title : String, val : float, high_or_low : String):
	var gui = body.modules.gameover.my_gui
	
	gui.get_node("Labels").set_visible(true)
	gui.get_node("Labels/Title").set_text(title)
	
	var round_val = round(val * 10)/10.0
	gui.get_node("Labels/Number").set_text(str(round_val))
	
	var type = "(highest)"
	if high_or_low == "low": type = "(lowest)"
	gui.get_node("Labels/Type").set_text(str(type))
