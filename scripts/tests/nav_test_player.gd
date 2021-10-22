extends Sprite

const DIST_UNTIL_POINT_REACHED : float = 5.0

var path = []

onready var nav = get_node("../Navigation2D")

func _input(ev):
	if ev is InputEventMouseButton and not ev.pressed:
		path = get_path_to_target(get_global_mouse_position())

func get_path_to_target(target_pos):
	# NOTE: third parameter is optimize => has issues
	var our_pos = get_position()
	var new_path = nav.get_simple_path(our_pos, target_pos)
	
	var max_tries = 10
	var num_tries = 0
	while path_contains_bounds(new_path) and num_tries < max_tries:
		target_pos = 0.5*(our_pos + target_pos)
		new_path = nav.get_simple_path(our_pos, target_pos)
		num_tries += 1
	
	if num_tries >= max_tries:
		print("NO PATH POSSIBLE")
		return []
	
	return new_path
	
func path_contains_bounds(arr):
	for point in arr:
		if point.x <= 0 or point.x >= 1919 or point.y <= 0 or point.y >= 1079:
			return true
	
	return false

func _physics_process(dt):
	move_to_next_point()

func move_to_next_point():
	if path.size() <= 0: return
	
	var next_point = path[0]
	
	var vec_to = (next_point - get_position())
	if vec_to.length() <= DIST_UNTIL_POINT_REACHED:
		path.remove(0)
		return

	set_position(get_position() + vec_to.normalized()*10.0)
