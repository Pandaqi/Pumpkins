extends Node2D

func _process(_dt):
	update()

func _draw():
	var shadow_makers = get_tree().get_nodes_in_group("ShadowMakers")
	
	var col = Color(0,0,0)
	for s in shadow_makers:
		var pos = s.get_global_position()
		
		if s.type == "circle":
			var radius = s.extents.x
			draw_circle(pos, radius, col)
		
		elif s.type == "rect":
			draw_set_transform(pos, s.global_rotation, Vector2(1, 1))
			
			var final_rect = Rect2(-s.extents, 2*s.extents)
			draw_rect(final_rect, col)
			
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))
