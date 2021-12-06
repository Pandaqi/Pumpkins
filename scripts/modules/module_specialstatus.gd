extends Node2D

onready var invincibility = $Invincibility
onready var stun = $Stun

onready var body = get_parent()

func on_being_sliced(throwable):
	if not throwable or not is_instance_valid(throwable): return
	
	if GlobalDict.cfg.invincibility_after_hit:
		invincibility.start(throwable)
	
	if GlobalDict.cfg.stun_after_hit:
		stun.start(throwable)
	
