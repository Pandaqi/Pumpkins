extends Node

var player_colors = [
	Color(1.0, 0.0, 0.0), 
	Color(0.0, 1.0, 0.0), 
	Color(0.0, 0.0, 1.0),
	Color(1.0, 1.0, 0.0)
]

var powerups = {
	"grow": { "frame": 1 },
	"shrink": { "frame": 2 },
	"morph": { "frame": 3 },
	"ghost": { "frame": 4, "temporary": true },
	"hungry": { "frame": 5, "temporary": true },
	"grow_range": { "frame": 6 },
	"shrink_range": { "frame": 7 },
	"extra_knife": { "frame": 8 },
	"lose_knife": { "frame": 9 },
	"boomerang": { "frame": 10, "temporary": true }
}
