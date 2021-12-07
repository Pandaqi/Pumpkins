extends StaticBody2D

onready var sprite = $Sprite

func _ready():
	pick_random_type()

func pick_random_type():
	var type = randi() % 4
	
	sprite.set_frame(type)
	for i in range(4):
		if i == type: continue
		get_node("Shape" + str(i+1)).queue_free()
