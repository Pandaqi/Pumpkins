extends Node2D

export var extents : Vector2 = Vector2(50,20)
export var type : String = "circle" # circle, rect, ??

func _on_Shaper_shape_updated():
	extents.x = get_node("../Shaper").approximate_radius()*1.5
