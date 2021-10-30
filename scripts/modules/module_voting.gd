extends Node2D

const MAX_OPTIONS : int = 4

var votes_per_option = []
var nodes_used_for_voting = []

onready var tween = $Tween
onready var particles = get_node("/root/Main/Particles")

func _ready():
	reset()

func cast_vote(node):
	tween.interpolate_property(node, "scale", 
		Vector2(1,1)*1.5, Vector2(1,1), 0.5, 
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()
	
	votes_per_option[node.option] += 1
	particles.general_feedback(node.global_position, "Voted!")
	
	if not node in nodes_used_for_voting:
		nodes_used_for_voting.append(node)

func reset():
	votes_per_option.resize(MAX_OPTIONS)
	for i in range(MAX_OPTIONS):
		votes_per_option[i] = 0
	
	for node in nodes_used_for_voting:
		particles.general_feedback(node.global_position, "Reset!")
	
	nodes_used_for_voting = []

func get_option_with_most_votes():
	var option = -1
	var votes = 0
	for i in range(MAX_OPTIONS):
		if votes_per_option[i] > votes:
			votes = votes_per_option[i]
			option = i
	
	return option

func request_and_reset_results():
	var result = get_option_with_most_votes()
	reset()
	return result
