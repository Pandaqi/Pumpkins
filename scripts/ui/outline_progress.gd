extends Node2D

var active : bool = false
var outline
var move_speed : float

export var color : Color = Color(0,0,0)
export var thickness : float = 10.0

func calculate_line_length(arr):
	var sum = 0
	for i in range(1, arr.size()):
		sum += (arr[i] - arr[i-1]).length()
	return sum

func start(ol, dur):
	outline = Array(ol)
	
	var full_length = calculate_line_length(outline)
	move_speed = full_length / dur
	
	active = true

func stop():
	outline = null
	active = false
	
	update()

func _physics_process(dt):
	if not active: return
	
	# move last point closer to the one before it
	var last_point = outline[outline.size() - 1]
	var prev_point = outline[outline.size() - 2]
	var vec = (prev_point - last_point).normalized()
	
	var new_last_point = last_point + vec*move_speed*dt
	outline[outline.size() - 1] = new_last_point
	
	update()
	
	# if close enough, completely remove it
	# (algorithm will continue with the new last point)
	if (new_last_point - prev_point).length() <= 3:
		outline.pop_back()
	
	# if too few points left, we're done, so stop
	if outline.size() <= 1: stop()

func _draw():
	if not active: return
	
	draw_polyline(outline, color, thickness, true)
	
	
