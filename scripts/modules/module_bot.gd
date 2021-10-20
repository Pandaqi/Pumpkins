extends Node

const PLAYER_SENSOR_RANGE : float = 300.0

onready var players = get_node("/root/Main/Players")
onready var body = get_parent()

var player_num : int = -1

var vel : Vector2
var is_throwing : bool

var num_knives : int
var active_knife_vec : Vector2

var points : int = 0
var area : float = 0.0

var closest : KinematicBody2D
var vec_to_closest : Vector2
var dist_to_closest : float

var players_close : Array
var num_players_close : int
var vec_away_from_close_players : Vector2
var avg_distance_to_players : float

func _ready():
	determine_personality()

func set_player_num(num):
	player_num = num

func determine_personality():
	pass

func _process(dt):
	read_situation()
	assign_scores()
	pick_best_input()
	apply_chosen_input()

func read_situation():
	var pos = body.get_global_position()
	
	# information about our own status
	vel = body.modules.mover.last_velocity
	is_throwing = body.modules.slasher.slashing_enabled
	
	num_knives = body.modules.knives.count()
	active_knife_vec = body.modules.knives.get_first_knife_vec()
	
	points = body.modules.collector.count()
	area = body.modules.shaper.area
	
	# information about knives/stuff we could get in the environment
	# TO DO
	
	# information about closest player
	closest = players.get_closest_to(pos)
	vec_to_closest = ((closest.get_global_position()) - pos).normalized()
	dist_to_closest = ((closest.get_global_position()) - pos).length()
	
	# general information about players
	players_close = players.get_all_within_range(pos, PLAYER_SENSOR_RANGE)
	num_players_close = players_close.size()
	
	var vec = Vector2.ZERO
	for p in players_close:
		vec += (pos - p.get_global_position())
	
	avg_distance_to_players = (vec / float(num_players_close)).length()
	vec_away_from_close_players = (vec / float(num_players_close)).normalized()
	
	# information about winning player
	# TO DO => if they are close to winning, make it a priority to attack them
	# TO DO => if our points are far behind, become more aggressive and take more risks
	
	# information about the physical environment
	# TO DO => Physical bodies blocking our path
	# TO DO => Any knifes nearby, especially those coming towards us

func assign_scores():
	pass

func pick_best_input():
	pass

func apply_chosen_input():
	pass
