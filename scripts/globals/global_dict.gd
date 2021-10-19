extends Node

var player_colors = [
	Color(1.0, 148/255.0, 122/255.0), 
	Color(177/255.0, 1.0, 140/255.0), 
	Color(139/255.0, 1.0, 251/255.0),
	Color(245/255.0, 148/255.0, 1.0),
	Color(141/255.0, 121/255.0, 25/255.0),
	Color(184/255.0, 191/255.0, 1.0)
]

var player_data = [
	{ "team": 0, "bot": false, "active": true },
	{ "team": 1, "bot": false, "active": true },
	{ "team": 2, "bot": false, "active": false },
	{ "team": 3, "bot": false, "active": false },
	{ "team": 4, "bot": false, "active": false },
	{ "team": 5, "bot": false, "active": false },
]

var predefined_shapes = {
	'circle': { 'frame': 0, 'basic': 'circle' },
	'square': { 'frame': 1, 'basic': 'square' },
	'triangle': { 'frame': 2, 'basic': 'triangle' },
	'pentagon': { 'frame': 3, 'basic': 'pentagon' },
	'hexagon': { 'frame': 4, 'basic': 'hexagon' },
	'parallellogram': { 'frame': 5, 'basic': 'square' },
	'l-shape': { 'frame': 6, 'basic': 'square' },
	'starpenta': { 'frame': 7, 'basic': 'pentagon' },
	'starhexa': { 'frame': 8, 'basic': 'hexagon' },
	'trapezium': { 'frame': 9, 'basic': 'square' },
	'crown': { 'frame': 10, 'basic': 'triangle' },
	'cross': { 'frame': 11, 'basic': 'octagon' },
	'heart': { 'frame': 12, 'basic': 'square' },
	'drop': { 'frame': 13, 'basic': 'square' },
	'arrow': { 'frame': 14, 'basic': 'triangle' },
	'diamond': { 'frame': 15, 'basic': 'pentagon' },
	'crescent': { 'frame': 16, 'basic': 'pentagon' },
	'trefoil': { 'frame': 17, 'basic': 'triangle' },
	'quatrefoil': { 'frame': 18, 'basic': 'octagon' }
}

var powerups = {
	"grow": { "frame": 1, "category": "shape" },
	"shrink": { "frame": 2, "category": "shape" },
	"morph": { "frame": 3, "category": "shape" },
	"ghost": { "frame": 4, "temporary": true, "category": "shape" },
	"hungry": { "frame": 5, "temporary": true, "category": "shape" },
	
	"grow_range": { "frame": 6, "category": "slashing" },
	"shrink_range": { "frame": 7, "category": "slashing" },
	"extra_knife": { "frame": 8, "category": "slashing" },
	"lose_knife": { "frame": 9, "category": "slashing" },
	"boomerang": { "frame": 10, "temporary": true, "category": "slashing" },
	"curved": { "frame": 11, "temporary": true, "category": "slashing" },
	"faster_throw": { "frame": 12, "category": "slashing" },
	"slower_throw": { "frame": 13, "category": "slashing"},
	
	"faster_move": { "frame": 14, "category": "moving" },
	"slower_move": { "frame": 15, "category": "moving" },
	"reversed_controls": { "frame": 16, "temporary": true, "category": "moving" },
	"ice": { "frame": 17, "temporary": true, "category": "moving" },
	
	"magnet": { "frame": 18, "temporary": true, "category": "collecting" },
	"duplicator": { "frame": 19, "temporary": true, "category": "collecting" },
	"clueless": { "frame": 20, "temporary": true, "category": "collecting" },
}
