extends StaticBody2D

const EXPLODE_FORCE : float = 2000.0

var fury : float = 0.0
var accepts_knives : bool = true

onready var fury_bar = $FuryBar
onready var fury_bar_content = $FuryBar/Content
onready var tween = $Tween
onready var explode_timer = $ExplodeTimer

func _ready():
	fury_bar.modulate.a = 0.0

func on_knife_entered(knife):
	if not accepts_knives: return
	
	var old_pos = knife.global_position
	var old_rot = knife.global_rotation
	
	knife.get_parent().remove_child(knife)
	add_child(knife)
	
	knife.set_position(to_local(old_pos))
	knife.set_rotation(old_rot - rotation)

	knife.modules.status.reset_to_forbidden_held_state()
	
	# a quick 'pop-up' effect to show hits
	tween.interpolate_property(self, "scale",
		Vector2(1,1)*1.3, Vector2(1,1), 0.3,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	var fury_impact = (randf()*0.25 + 0.25)

	change_fury(fury_impact)

func change_fury(df):
	fury = clamp(fury + df, 0.0, 1.0)
	
	tween_fury_bar()
	
	if fury >= 1.0:
		explode()

func tween_fury_bar():
	var start_scale = fury_bar_content.scale
	var target_scale = Vector2(fury, 1)
	
	if start_scale.x > target_scale.x:
		start_scale.x = 0
	
	tween.interpolate_property(fury_bar_content, "scale", 
		start_scale, target_scale, 0.3,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	fury_bar.modulate.a = 1.0
	tween.interpolate_property(fury_bar, "modulate",
		Color(1,1,1,1), Color(1,1,1,0), 3.0,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	tween.start()

func explode():
	fury = 0.0
	accepts_knives = false
	remove_from_group("Stuckables")
	
	explode_timer.start()

	GlobalAudio.play_dynamic_sound(self, "explode")
	throw_all_knives()

func throw_all_knives():
	for child in get_children():
		if not child.is_in_group("Throwables"): continue

		child.modules.thrower.throw_from_object(self, EXPLODE_FORCE)

func _on_ExplodeTimer_timeout():
	accepts_knives = true
	add_to_group("Stuckables")
