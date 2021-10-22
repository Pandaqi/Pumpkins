extends Node2D

func _ready():
	var trans = $A/CollisionPolygon2D.get_global_transform()
	var polyA = Array($A/CollisionPolygon2D.polygon)
	for i in range(polyA.size()):
		polyA[i] = trans.xform(polyA[i])
	
	trans = $B/CollisionPolygon2D.get_global_transform()
	var polyB = Array($B/CollisionPolygon2D.polygon)
	for i in range(polyB.size()):
		polyB[i] = trans.xform(polyB[i])
	
	print(polyA)
	print(polyB)
	
	#$A/CollisionPolygon2D.polygon = Geometry.intersect_polygons_2d(polyA, polyB)[0]
	$A/CollisionPolygon2D.polygon = Geometry.clip_polygons_2d(polyA, polyB)[0]
	$B.queue_free()
