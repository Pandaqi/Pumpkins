extends Node2D

export var type : String = "arenas"

var texture = null
var hover_texture = null

var frames = Vector2.ZERO

var item_list = []
var item_grid = []

var base_item_scale : Vector2 = Vector2(0.5,0.5)
var glow_scale : Vector2 = Vector2(1,1)
var margin_between_items = 32.0
var item_size = Vector2(1,1) * (128 + margin_between_items)

var item_header_scene = preload("res://scenes/gui/item_header.tscn")
var item_list_scene = preload("res://scenes/gui/item.tscn")

var focus_pos : Vector2 
var focus_cell = null

var enabled : bool = false

var cols
var rows
var single_choice_mode : bool = false
var large_tiles : bool = false

var cur_flick_dir = Vector2.ZERO
var last_flick_time = 0

var use_joystick_to_switch_screens : bool
var add_reset_and_random_buttons : bool

func enable():
	enabled = true

func disable():
	enabled = false

func _ready():
	use_joystick_to_switch_screens = GlobalDict.cfg.navigate_settings_with_joystick
	add_reset_and_random_buttons = GlobalDict.cfg.add_default_settings_buttons

	var data = GlobalDict.nav_data[type]
	
	frames = data.frames
	single_choice_mode = data.single_choice_mode
	cols = data.cols
	large_tiles = data.large_tiles
	
	if large_tiles: item_size *= 1.66
	else: glow_scale *= 0.5
	
	texture = load("res://assets/ui/settings/" + type + ".png")
	hover_texture = load("res://assets/ui/settings/" + type + "_hover.png")
	item_list = GlobalDict.get_list_corresponding_with_key(type)
	
	var header_text = type.capitalize()
	$Container.add_child(item_header_scene.instance())
	$Container/Header/Label.set_text(header_text)
	
	create_item_list_visuals()

func create_item_list_visuals():
	var keys = item_list.keys()
	var total_num_items = keys.size()
	if should_add_default_buttons(): total_num_items += 2
	
	rows = ceil(total_num_items / float(cols))

	item_grid.resize(cols)
	for x in range(cols):
		item_grid[x] = []
		item_grid[x].resize(rows)
		
		for y in range(rows):
			var index = x + y*cols
			
			if index >= keys.size(): continue

			var key = keys[index]
			var s = item_list_scene.instance()
			
			var sprite = s.get_node("Sprite")
			sprite.texture = texture
			sprite.hframes = frames.x
			sprite.vframes = frames.y
			
			var hover = s.get_node("Hover")
			hover.texture = hover_texture
			hover.hframes = frames.x
			hover.vframes = frames.y
			
			# Arguments = frame, specific item type, our type ( = section in config)
			var item_type = key
			var frame_index = item_list[key].frame

			s.set_data(item_list[key])
			s.set_type(frame_index, item_type, type)
			s.set_size(base_item_scale, glow_scale)
			
			 # IMPORTANT: must happen before reading values from config!
			s.single_choice_mode = single_choice_mode
			s.populator_node = self
			s.grid_pos = Vector2(x,y)
			s.read_value_from_config()

			s.set_position(Vector2(x,y)*item_size)
			$Container.add_child(s)
			
			item_grid[x][y] = s
	
	place_default_buttons()
	
	focus_on(Vector2.ZERO)
	
	var center_of_screen = 0.5*Vector2(1920, 1080)
	var offset = Vector2(0.5*(cols-1), 0.5*(rows-1))*item_size
	$Container.set_position(center_of_screen - offset)
	
	var header_offset = -150
	if large_tiles: header_offset *= 2
	$Container/Header.set_position(Vector2(offset.x, header_offset))

func should_add_default_buttons():
	if single_choice_mode: return false
	if not add_reset_and_random_buttons: return false
	return true

func place_default_buttons():
	if not should_add_default_buttons(): return
	
	var reset_placed = false
	var random_placed = false
	
	for x in range(cols):
		for y in range(rows):
			if item_grid[x][y]: continue
			if reset_placed and random_placed: break
			
			var s = item_list_scene.instance()
			
			if not reset_placed:
				s.make_reset_button()
				reset_placed = true
			else:
				s.make_random_button()
				random_placed = true
			
			s.set_size(base_item_scale, glow_scale)
			s.set_position(Vector2(x,y)*item_size)
			$Container.add_child(s)
			item_grid[x][y] = s
			
			s.populator_node = self

func reset_all_options():
	var all_disabled = true
	
	for x in range(cols):
		for y in range(rows):
			if not item_grid[x][y]: continue
			if item_grid[x][y].ignore_default_buttons(): continue
			if item_grid[x][y].is_on(): 
				all_disabled = false
				break
	
	for x in range(cols):
		for y in range(rows):
			if not item_grid[x][y]: continue
			if item_grid[x][y].ignore_default_buttons(): continue
			item_grid[x][y].reset(all_disabled)

func randomize_all_options():
	for x in range(cols):
		for y in range(rows):
			if not item_grid[x][y]: continue
			if item_grid[x][y].ignore_default_buttons(): continue
			
			item_grid[x][y].randomize_me()

func focus_on(pos : Vector2):
	if focus_cell:
		focus_cell.unfocus()
	
	focus_cell = item_grid[pos.x][pos.y]
	focus_pos = pos
	focus_cell.focus()

func _input(ev):
	if not enabled: return
	if get_parent().tween_is_busy(): return
	
	var has_moved = check_movement(ev) # for moving through the grid
	
	if has_moved: return
	check_toggle(ev) # for toggling current thing on/off

func check_movement(ev):
	var offset = Vector2.ZERO
	
	# these are for button PRESSES (on arrow keys or D-pad controller)
	if ev.is_action_released("ui_left"):
		offset = Vector2.LEFT
	elif ev.is_action_released("ui_right"):
		offset = Vector2.RIGHT
	elif ev.is_action_released("ui_up"):
		offset = Vector2.UP
	elif ev.is_action_released("ui_down"):
		offset = Vector2.DOWN
	
	# these are for detecting a FLICK from a controller joystick
	var flick_offset = detect_flick(ev)
	offset += flick_offset

	if offset.length() < 0.05: return false
	
	var new_pos = keep_within_grid(focus_pos, offset)
	GlobalAudio.play_static_sound("ui_selection_change")
	
	focus_on(new_pos)
	return true

func detect_flick(ev):
	if not (ev is InputEventJoypadMotion): return Vector2.ZERO
	
	var threshold_high = 0.8
	var threshold_low = 0.2
	
	# check if an older flick ended?
	var h = Input.get_action_strength("right_0") - Input.get_action_strength("left_0")
	var v = Input.get_action_strength("down_0") - Input.get_action_strength("up_0")
	
	var joystick_vec = Vector2(h,v).normalized()
	
	if joystick_vec.length() <= threshold_low:
		var time_diff = (OS.get_ticks_msec() - last_flick_time)
		var flick_threshold = 600 
		if time_diff < flick_threshold and cur_flick_dir != Vector2.ZERO:
			var offset = cur_flick_dir
			cur_flick_dir = Vector2.ZERO
			last_flick_time = 0
			return offset
	
	# start a new flick?
	if Input.get_action_strength("left_0") > threshold_high:
		cur_flick_dir = Vector2.LEFT
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("right_0") > threshold_high:
		cur_flick_dir = Vector2.RIGHT
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("up_0") > threshold_high:
		cur_flick_dir = Vector2.UP
		last_flick_time = OS.get_ticks_msec()
	elif Input.get_action_strength("down_0") > threshold_high:
		cur_flick_dir = Vector2.DOWN
		last_flick_time = OS.get_ticks_msec()
	
	return Vector2.ZERO

func check_toggle(ev):
	var toggle_action = ev.is_action_released("config_toggle")
	if not toggle_action: return
	
	execute_toggle()

func execute_toggle():
	if single_choice_mode:
		# already on, change nothing
		if focus_cell.is_on(): return
		
		# first, disable EVERYTHING
		# the code below will just enable the one thing we want
		disable_all_cells()
	
	focus_cell.toggle()
	GlobalAudio.play_static_sound("ui_button_press")

func disable_all_cells():
	for x in range(cols):
		for y in range(rows):
			var node = item_grid[x][y]
			if not node: continue
			
			if node.is_on(): node.toggle()

func keep_within_grid(original_pos : Vector2, offset : Vector2):
	var pos = original_pos + offset
	var bounds = Vector2(item_grid.size(), item_grid[0].size())
	
	if pos.x < 0: 
		if use_joystick_to_switch_screens: get_parent().advance_screen(-1)
		pos.x = 0
	elif pos.x >= bounds.x: 
		if use_joystick_to_switch_screens: get_parent().advance_screen(+1)
		pos.x = bounds.x-1
	
	if pos.y < 0: pos.y = 0
	elif pos.y >= bounds.y: pos.y = bounds.y-1
	
	if not item_grid[pos.x][pos.y]: 
		if offset.x < 0 and use_joystick_to_switch_screens: 
			get_parent().advance_screen(-1)
		elif offset.x > 0 and use_joystick_to_switch_screens:
			get_parent().advance_screen(+1)
			
		return original_pos
	
	return pos
