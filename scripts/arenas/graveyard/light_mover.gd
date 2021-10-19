extends Light2D

var positions = [Vector2(0, 0.5*1080), Vector2(0.5*1920, 0.5*1080), Vector2(1920, 0.5*1080)]
var cur_index : int
var target_pos

func _ready():
	cur_index = 1
	$Timer.start()

func _physics_process(dt):
	if not target_pos: return
	
	set_position(lerp(get_position(), target_pos, dt))

func _on_Timer_timeout():
	cur_index = (cur_index + 1) % int(positions.size())
	target_pos = positions[cur_index]
