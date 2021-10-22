extends CanvasLayer

var radius : float = 3000.0
onready var mat = $ColorRect.material
onready var mode = get_node("../ModeManager")

const TIME_UNTIL_GAME_END : float = 300.0 # seconds
var shrink_speed : float

func _ready():
	if not GlobalDict.cfg.shrink_area or not mode.players_can_die():
		self.queue_free()
	
	shrink_speed = radius / TIME_UNTIL_GAME_END

func _physics_process(dt):
	radius -= shrink_speed * dt
	mat.set_shader_param("radius", radius)
	
	check_players_inside()

func check_players_inside():
	var players = get_tree().get_nodes_in_group("Players")
	
	var center = 0.5*Vector2(1920, 1080)
	for p in players:
		if p.modules.status.is_dead: continue
		
		var dist_to_center = (p.get_global_position() - center).length()
		if dist_to_center >= radius: continue
		
		p.modules.status.die()
