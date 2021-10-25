extends Node2D

const DAMPING : float = 0.925
const REPEL_FORCE : float = 300.0

var knockback_force : Vector2 = Vector2.ZERO
onready var body = get_parent()
onready var area = $Area2D

var disabled : bool = false

func _physics_process(_dt):
	if disabled: return
	
	check_force()
	repel_hostile_entities()

func disable():
	disabled = true

func apply(force):
	knockback_force = force

func check_force():
	if knockback_force.length() <= 0.03: return

	body.move_and_slide(knockback_force)
	knockback_force *= DAMPING
	
	if knockback_force.length() <= 4.0:
		knockback_force = Vector2.ZERO
		return

func repel_hostile_entities():
	var bodies = area.get_overlapping_bodies()
	var num_repels = 0
	var avg_vec_away = Vector2.ZERO
	for b in bodies:
		if b == body: continue # it's ourselves
		if same_team(b): continue
		
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
