extends Node2D

const DAMPING : float = 0.925
const WATER_DAMPING : float = 0.99
const REPEL_FORCE : float = 300.0

var knockback_force : Vector2 = Vector2.ZERO
var area = null
onready var body = get_parent()


var disabled : bool = false

func _ready():
	if has_node("Area2D"): 
		area = $Area2D

func _physics_process(_dt):
	if disabled: return
	
	check_force()
	repel_hostile_entities()

func disable():
	disabled = true

func remove():
	knockback_force = Vector2.ZERO

func apply(force):
	knockback_force = force

func check_force():
	if knockback_force.length() <= 0.03: return

	body.move_and_slide(knockback_force)
	
	var cur_damping = DAMPING
	if body.modules.status.in_water: cur_damping = WATER_DAMPING
	knockback_force *= cur_damping
	
	if knockback_force.length() <= 4.0:
		knockback_force = Vector2.ZERO
		return

func repel_hostile_entities():
	if not area: return
	
	var bodies = area.get_overlapping_bodies()
	var num_repels = 0
	var avg_vec_away = Vector2.ZERO
	for b in bodies:
		if not b.is_in_group("Players"): return
		if b == body: continue # it's ourselves
		if same_team(b): continue # it's a teammate
		if b.modules.status.is_dead: continue # it's a ghost
		
		var vec_away = (b.global_position - body.global_position).normalized()
		var force = vec_away * REPEL_FORCE
		avg_vec_away += vec_away
		
		b.modules.knockback.apply(force)
		num_repels += 1
	
	if num_repels <= 0: return
	
	var force = -1 * (avg_vec_away / float(num_repels)) * REPEL_FORCE
	apply(force)

func same_team(other_body):
	var my_team = body.modules.status.team_num
	var their_team = other_body.modules.status.team_num
	return my_team == their_team
