extends Node2D

# Heavily simplified version of actual module system
# As the dumpling doesn't need more
# TO DO: Or implement it anyway for consistency?
onready var modules = {
	'status': $Status,
	'shaper': $Shaper
}
