extends Node2D

func open():
	$Sprite.set_visible(false)
	$ThrowableDeleter.activate()

func close():
	$Sprite.set_visible(true)
	$ThrowableDeleter.deactivate()
