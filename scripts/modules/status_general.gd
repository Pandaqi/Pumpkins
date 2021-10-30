extends Node2D

var in_water : bool = false
var player_num : int = -1
var team_num : int = -1

func enter_water():
	in_water = true

func exit_water():
	in_water = false

func react_to_areas():
	return true
