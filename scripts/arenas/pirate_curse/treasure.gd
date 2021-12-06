extends Node2D

const MAX_VELOCITY : float = 100.0

var player_num : int = -1
var type : String = ""

var frames = ["heart", "destroy", "self_slice", "curse", "free_point", "big_curse"]
var curse_powerups = ["slower_move", "slower_throw", "reversed_controls", "ice", "shrink"]

onready var body = get_parent()
onready var mode = get_node("/root/Main/ModeManager")
onready var players = get_node("/root/Main/Players")
onready var spawner = get_node("/root/Main/Spawner")
onready var particles = get_node("/root/Main/Particles")

func set_random_type():
	set_type(frames[randi() % frames.size()])

func set_type(tp):
	type = tp
	
	var frame = frames.find(tp)
	get_node("../Sprite").set_frame(frame)

func _physics_process(dt):
	var vel = body.get_linear_velocity()
	if vel.length() > MAX_VELOCITY:
		vel = vel.normalized() * MAX_VELOCITY
		body.set_linear_velocity(vel)

func delete(attacking_throwable):
	handle_functionality(attacking_throwable)
	body.queue_free()

func handle_functionality(attacking_throwable):
	var fb = "?"
	var attacker = attacking_throwable.modules.owner.get_owner()
	
	# Just a fail-safe; this function should never trigger on a throwable WITHOUT an owner
	if not attacker: return
	
	match type:
		"heart":
			fb = "Revive!"
			players.revive_last_dead()
			
		"destroy":
			fb = "Destroyed!"
			attacking_throwable.modules.status.delete()
		
		"self_slice":
			fb = "Sliced yourself!"
			attacker.modules.slasher.self_slice()
		
		"curse":
			fb = "Curse!"
			
			var num_powerups = randi() % 2 + 1
			curse_powerups.shuffle()
			for i in range(num_powerups):
				attacker.modules.powerups.grab(null, curse_powerups[i], false)
		
		"free_point":
			if mode.win_type_is('collection'):
				fb = "Collect!"
				attacker.modules.collector.collect(1)
			else:
				fb = "Grow!"
				attacker.modules.grower.grow(0.2)
		
		"big_curse":
			fb = "Curse for All!"
			
			var all_players = get_tree().get_nodes_in_group("Players")
			for p in all_players:
				var params = {
					'body_radius': p.modules.shaper.approximate_radius(),
					'avoid_players': 100.0
				}
				
				var pos = spawner.get_valid_pos(params)
				p.modules.teleporter.teleport(pos)
				
				curse_powerups.shuffle()
				p.modules.powerups.grab(null, curse_powerups[0], false)
	
	particles.general_feedback(body.global_position, fb)
