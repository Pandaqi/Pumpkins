extends Node

var base_cfg = {
	'game_mode': 'slicey_dicey',
	'arena': 'graveyard',
	'powerups': [],
	
	'max_players': 6,
	'auto_pickup_powerups': false,
	'num_starting_knives': 1,

	'use_slidy_throwing': false,
	'auto_throw_knives': false,
	
	'navigate_settings_with_joystick': true,
	'add_default_settings_buttons': true,
}

var cfg = {}

var modes = {
	"dicey_slicey": { "frame": 0, "win": "survival", "fade_rubble": true, "players_can_die": true, "def": true },
	
	"collect_em_all": { "frame": 1, "win": "collection", "eat_player_parts": true, "target_num": 10, "auto_grow": true, "collectible_group": "PlayerParts" },
	
	"bulls_eye": { "frame": 2, "win": "collection", "target_num": 20, "fade_rubble": true, "auto_grow": true, "auto_spawns": "bullseye", "player_slicing_penalty": -1, "target_group": "Targets", "num_starting_knives": 3 },
	
	"frightening_feast": { "frame": 3, "win": "collection", "target_num": 10, "auto_spawns": "dumplings", "collectible_group": "Dumplings" },
	
	"dwarfing_dumplings": { "frame": 4,"win": "survival", "fade_rubble": true, "target_group": "Dumplings", "players_can_die": true },
	
	"ropeless_race": { "frame": 5, "win": "survival", "forbid_slicing_players": true, "fade_rubble": true, "players_can_die": true }
}

var arenas = {
	"spooky_forest": { "frame": 0, "def": true },
	"graveyard": { "frame": 1 }
}

var configurable_settings = {
	"tutorial": { "frame": 0, "def": true },
	"aim_helper": { "frame": 1, "def": false },
	"knife_always_in_front": { "frame": 2, "def": false },
	"disable_flashing_effects": { "frame": 3, "def": false },
	"shrink_area": { "frame": 4, "def": false },
	"show_guides": { "frame": 5, "def": true },
	"everyone_starts_pumpkin": { "frame": 6, "def": false },
	"stuck_reset": { "frame": 7, "def": true }
}

var throwables = {
	"knife": { "body": false, "needs_owner": true },
	"dumpling": { "body": true, "needs_owner": false } 
}

var player_colors = [
	Color(1.0, 148/255.0, 122/255.0), 
	Color(177/255.0, 1.0, 140/255.0), 
	Color(139/255.0, 1.0, 251/255.0),
	Color(245/255.0, 148/255.0, 1.0),
	Color(141/255.0, 121/255.0, 25/255.0),
	Color(184/255.0, 191/255.0, 1.0),
	Color(198/255.0, 230/255.0, 92/255.0),
	Color(198/255.0, 151/255.0, 1.0),
]

var player_data = [
	{ "team": 0, "bot": false, "active": true },
	{ "team": 1, "bot": true, "active": true },
	{ "team": 2, "bot": false, "active": false },
	{ "team": 3, "bot": false, "active": false },
	{ "team": 4, "bot": false, "active": false },
	{ "team": 5, "bot": false, "active": false },
	{ "team": 6, "bot": false, "active": false },
	{ "team": 7, "bot": false, "active": false }
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
	"grow": { "frame": 1, "category": "shape", "prob": 5, "def": true },
	"shrink": { "frame": 2, "category": "shape", "prob": 5, "def": true },
	"morph": { "frame": 3, "category": "shape", "def": true },
	"ghost": { "frame": 4, "temporary": true, "category": "shape" },
	"hungry": { "frame": 5, "temporary": true, "category": "shape" },
	
	"grow_range": { "frame": 6, "category": "slashing" },
	"shrink_range": { "frame": 7, "category": "slashing" },
	"extra_knife": { "frame": 8, "category": "slashing", "prob": 5, "def": true },
	"lose_knife": { "frame": 9, "category": "slashing", "def": true },
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
	
	"repel_knives": { "frame": 21, "temporary": true, "category": "slashing", "def": true, "prob": 3 },
	"auto_unwrap": { "frame": 22, "temporary": true, "category": "collecting" },
	
	"dumpling": { "frame": 23, "category": "throwables", "def": true, "prob": 5 }
}

func update_from_current_config():
	cfg = {}
	
	# make a DEEP copy of the original config
	for key in base_cfg:
		var new_prop = base_cfg[key]

		if new_prop is Array or new_prop is Dictionary:
			new_prop = str2var( var2str(new_prop) )

		cfg[key] = new_prop
	
	# Now override with new settings where needed
	
	# ARENA
	for key in arenas:
		if GlobalConfig.read_game_config("arenas", key):
			cfg.arena = key
			break
	
	# MODE
	for key in modes:
		if GlobalConfig.read_game_config("modes", key):
			cfg.game_mode = key
			break
	
	# POWERUPS
	var powerups_included = []
	for key in powerups:
		if GlobalConfig.read_game_config("powerups", key):
			powerups_included.append(key)
	
	cfg.powerups = powerups_included
	
	# RULES
	for key in configurable_settings:
		var val = GlobalConfig.read_game_config("settings", key)
		cfg[key] = val

func is_mobile():
	return (OS.get_name() == "Android" or OS.get_name() == "iOS")
