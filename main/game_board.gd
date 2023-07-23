class_name GameBoard extends Node2D

const TILE_SCENE: PackedScene = preload("res://main/tiles/tile.tscn")
const BARRIER_SCENE: PackedScene = preload("res://main/tiles/barrier.tscn")
const TRAIN_SCENE: PackedScene = preload("res://main/trains/train.tscn")
const POWERUP_SCENE: PackedScene = preload("res://main/tiles/powerup.tscn")

const BASE_RES_X = 480
const BASE_RES_Y = 640
const SCREEN_SCALING_FACTOR: float = 2

const GRID_SIZE: int = 16
const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 13
const GRID_X_OFFSET: int = BASE_RES_X / 10
const GRID_Y_OFFSET: int = BASE_RES_Y / 30
const GRID_START_X: int = GRID_X_OFFSET + int((BASE_RES_X / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_WIDTH) / 2)

const RUNWAY_LENGTH: int = 5
const NUM_RUNWAYS: int = (GRID_WIDTH - 1) / 2
const YOFFSET: int = RUNWAY_LENGTH * GRID_SIZE
const GRID_START_Y: int = GRID_Y_OFFSET + int(((BASE_RES_Y + YOFFSET) / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_HEIGHT) / 2)
const TILE_SPAWN_START: Vector2i = Vector2i(GRID_START_X, 0 - GRID_SIZE)

enum DEBUG_BOARD {NONE, TEST_CLEAR_1, TEST_CLEAR_4, TEST_CLEAR_SPLIT_3}

var available_runways = range(1, NUM_RUNWAYS + 1)

@onready var playable_area: NinePatchRect = $playable_area
@onready var tiles: Node2D = $tiles
@onready var barriers: Node2D = $barriers
@onready var trains: Node2D = $trains
@onready var runway: Node2D = $runway
@onready var tile_cursor: Sprite2D = $tile_cursor
@onready var blocks: Node2D = $blocks
@onready var mountain: Sprite2D = $mountain
@onready var powerups: Node2D = $powerups

const selection_tile_weights: Dictionary = {
	Tile.TileID.VERT: 0.5,
	Tile.TileID.HORIZ: 0.5,
	Tile.TileID.CROSS: 0.75,
	Tile.TileID.LEFT_UP: 0.3,
	Tile.TileID.RIGHT_UP: 0.3,
	Tile.TileID.LEFT_DOWN: 0.3,
	Tile.TileID.RIGHT_DOWN: 0.3,
	Tile.TileID.RIGHT_SWITCHBACK: 0.75,
	Tile.TileID.LEFT_SWITCHBACK: 0.75
}

const selection_powerup_weights: Dictionary = {
	Powerup.PowerupID.NONE: 0.006,
#	Powerup.PowerupID.NUKE: 0.05,
	Powerup.PowerupID.NUKE: 100.0,
	Powerup.PowerupID.PIKE: 0.2,
	Powerup.PowerupID.SPREAD: 0.2,
	Powerup.PowerupID.MULTIPLIER: 0.3
}

var accumulated_tile_weights: Dictionary
var overall_tile_weight: float

var accumulated_powerup_weights: Dictionary
var overall_powerup_weight: float

var new_tile: Tile
var current_active_tile: Tile
var rows_to_clear: Array[int]
var modifiers: Array = []

var tiles_reference: Dictionary = {}
var barriers_reference: Dictionary = {}
var powerups_reference: Dictionary = {}

var train_step_timer: Timer = Timer.new()
var speedup_cooldown_timer: Timer = Timer.new()
var speedup_cooldown_time: float = 10.0

var global_mouse_pos: Vector2
var prev_mouse_pos: Vector2
var active_mouse_grid_pos: Vector2i

var speedup_active: bool = false
var speedup_cooldown_active: bool = false

func _ready() -> void:
	var debug_mode: DEBUG_BOARD = DEBUG_BOARD.TEST_CLEAR_4
#	var debug_mode: DEBUG_BOARD = DEBUG_BOARD.NONE
	randomize()
	_create_playable_area()
	_setup_random_tile_weights()
	_setup_random_powerup_weights()
	_create_board(debug_mode)
	_create_barriers()
	# Set cursor
	tile_cursor.initialise_cursor()
	current_active_tile = tiles_reference[Vector2i(0, GRID_HEIGHT - 1)]
	current_active_tile.set_is_selected(true)
	SignalBus.connect("tile_rotated", _on_tile_rotated)
	SignalBus.connect("train_converted_to_blocks", _on_train_converted_to_blocks)
	GameScore.connect("level_reached", _on_level_reached)
	if debug_mode == DEBUG_BOARD.TEST_CLEAR_1 or debug_mode == DEBUG_BOARD.TEST_CLEAR_4:
		spawn_train(1)
	else:
		spawn_train()
	_create_train_timer()


func _process(_delta: float) -> void:
	global_mouse_pos = get_global_mouse_position()
	var new_grid_position: Vector2i
	if GameControl.game_active:
		if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_up"):
			var vert_move = Input.get_axis("move_up", "move_down")
			var horiz_move = Input.get_axis("move_left", "move_right")
			new_grid_position = tile_cursor.move_cursor_grid_with_animate(Vector2i(horiz_move, vert_move), true)
			active_mouse_grid_pos = new_grid_position  # Use this in case of a mouse takeover
			_select_active_tile(new_grid_position)
			
		elif global_mouse_pos != prev_mouse_pos:
			# Detected mouse input
			for tile_pos in tiles_reference.keys():
				if tiles_reference[tile_pos].tile_rect.has_point(global_mouse_pos) and tile_pos != active_mouse_grid_pos and tiles_reference[tile_pos].is_selectable:
					active_mouse_grid_pos = tile_pos
					new_grid_position = tile_cursor.move_cursor_grid_with_animate(active_mouse_grid_pos, false)
					_select_active_tile(tile_pos)
					break
		prev_mouse_pos = get_global_mouse_position()
	
		if speedup_cooldown_active and speedup_active:
			# This will help unsuspecting players that rush the start of the new train
			speedup_active = false
			train_step_timer.wait_time = GameControl.train_step_time
			_restart_step_timer()   
	
		if Input.is_action_pressed("speed_up") and not speedup_cooldown_active:
			train_step_timer.wait_time = GameControl.min_train_step_time
			if not speedup_active:
				speedup_active = true
				_restart_step_timer()
			
		if Input.is_action_just_released("speed_up"):
			train_step_timer.wait_time = GameControl.train_step_time
			if speedup_active:
				speedup_active = false
				_restart_step_timer()
			if speedup_cooldown_active:
				speedup_cooldown_active = false  # Allow speedup again


func _restart_step_timer() -> void:
	# Used when there is a new time
	train_step_timer.stop()
	train_step_timer.start()


func _select_active_tile(new_grid_position: Vector2i):
	current_active_tile.set_is_selected(false)
	current_active_tile = tiles_reference[new_grid_position]
	current_active_tile.set_is_selected(true)


func _create_playable_area() -> void:
	var playable_area_pos = Vector2i(GRID_START_X - playable_area.patch_margin_left, GRID_START_Y - playable_area.patch_margin_top)
	var playable_area_size = Vector2i(GRID_SIZE * GRID_WIDTH + 2 * playable_area.patch_margin_left, GRID_SIZE * GRID_HEIGHT + 2 * playable_area.patch_margin_top)
	playable_area.global_position = playable_area_pos
	playable_area.size = playable_area_size


func sum_array(array: Array) -> float:
		# Lazy - cannot handle non floats
		var n: float = 0.0
		
		for x in array:
			n += x
		return n


func _setup_random_tile_weights() -> void:
	randomize()
	accumulated_tile_weights = {}
	var tracked_weight = 0.0
	for tile_id in selection_tile_weights.keys():
		tracked_weight += selection_tile_weights[tile_id]
		accumulated_tile_weights[tile_id] = tracked_weight
		
	overall_tile_weight = sum_array(selection_tile_weights.values())
	# Weight initialisation complete!


func _setup_random_powerup_weights() -> void:
	randomize()
	accumulated_powerup_weights = {}
	var tracked_weight = 0.0
	for powerup_id in selection_powerup_weights.keys():
		tracked_weight += selection_powerup_weights[powerup_id]
		accumulated_powerup_weights[powerup_id] = tracked_weight
		
	overall_powerup_weight = sum_array(selection_powerup_weights.values())
	print(accumulated_powerup_weights)
	# Weight initialisation complete!


func _select_random_powerup() -> Powerup.PowerupID:
	var roll: float = randf_range(0.0, overall_powerup_weight)
	for powerup_id in accumulated_powerup_weights.keys():
		if accumulated_powerup_weights[powerup_id] > roll:
			return powerup_id
	return Powerup.PowerupID.NONE


func _select_random_tile() -> Tile.TileID:
	var roll: float = randf_range(0.0, overall_tile_weight)
	for tile_id in accumulated_tile_weights.keys():
		if accumulated_tile_weights[tile_id] > roll:
			return tile_id
	return Tile.TileID.EMPTY


func _create_standard_board() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = Vector2(GRID_START_X + x * GRID_SIZE, GRID_START_Y + y * GRID_SIZE)
			tiles.add_child(new_tile)
			var new_tile_coord: Vector2i = Vector2i(x, y)
			tiles_reference[new_tile_coord] = new_tile
			new_tile.set_tile_coord(new_tile_coord)
			barriers_reference[new_tile_coord] = []
	
	for tile_ref in tiles_reference.values():
		tile_ref.set_tile(_select_random_tile())


func _create_clearable_board(num_clearable_rows: int) -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = Vector2(GRID_START_X + x * GRID_SIZE, GRID_START_Y + y * GRID_SIZE)
			tiles.add_child(new_tile)
			var new_tile_coord: Vector2i = Vector2i(x, y)
			tiles_reference[new_tile_coord] = new_tile
			new_tile.set_tile_coord(new_tile_coord)
			new_tile.set_tile(Tile.TileID.VERT)

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT - num_clearable_rows - 2, GRID_HEIGHT - 2):
			if x == 1:
				continue
			tiles_reference[Vector2i(x, y)].convert_to_block(Color.DIM_GRAY)


func _create_board(debug_option: DEBUG_BOARD = DEBUG_BOARD.NONE) -> void:
	match debug_option:
		DEBUG_BOARD.NONE:
			_create_standard_board()
		DEBUG_BOARD.TEST_CLEAR_1:
			_create_clearable_board(1)
		DEBUG_BOARD.TEST_CLEAR_4:
			_create_clearable_board(4)

	# Add in runway (always)
	var runway_pos: Vector2i
	var runway_y_offset = GRID_START_Y - (RUNWAY_LENGTH - 1) * GRID_SIZE
	for x in range(1, GRID_WIDTH, 2):
		for y in range(RUNWAY_LENGTH - 1):
			runway_pos = Vector2i(GRID_START_X + x * GRID_SIZE, runway_y_offset + y * GRID_SIZE)
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = runway_pos
			runway.add_child(new_tile)
			if y == 0:
				new_tile.show_tunnel()
			new_tile.set_tile(Tile.TileID.VERT)
			new_tile.set_is_selectable(false)
			tiles_reference[Vector2i(x, y - RUNWAY_LENGTH + 1)] = new_tile

	# Place mountain
	mountain.global_position = Vector2i(GRID_START_X / 3 + 5, GRID_START_Y - GRID_SIZE * 7)


func _flatten_connection_points(input_array: Array) -> Array[int]:
	var output_array: Array[int] = []
	for element in input_array:
		if element is Array:
			output_array += _flatten_connection_points(element)
		else:
			output_array.append(element)
	return output_array


func _add_single_barrier_to_tile(tile_id: Vector2i, barrier_id: int, invisible: bool = false) -> void:
	var new_barrier = BARRIER_SCENE.instantiate()
	new_barrier.global_position = Vector2(GRID_START_X + tile_id.x * GRID_SIZE, GRID_START_Y + tile_id.y * GRID_SIZE)
	barriers.add_child(new_barrier)
	if invisible:
		new_barrier.hide_barrier()
	new_barrier.set_barrier_id(barrier_id)
	
	if tile_id not in barriers_reference:
		barriers_reference[tile_id] = []
	barriers_reference[tile_id].append(new_barrier)


func _resolve_barrier_to_tile(
	current_tile_coord: Vector2i, 
	current_tile_connection_point: int,
	adjacent_tile_coord: Vector2i, 
	adjacent_target_connection_point: int
	) -> void:
	
	var current_tile_ref: Tile = tiles_reference[current_tile_coord]
	var current_connection_points: Array[int] = _flatten_connection_points(Tile.TILE_ENTRY_EXIT_PAIRS[current_tile_ref.tile_id])
	var adjacent_tile_ref: Tile = tiles_reference.get(adjacent_tile_coord)
	if adjacent_tile_ref == null:
		if adjacent_tile_coord in barriers_reference:
			for barrier_ref in barriers_reference[adjacent_tile_coord]:
				barrier_ref.queue_free()
			barriers_reference[adjacent_tile_coord] = []
		# Special capture here for two cases:
		# - one - board edges
		# - two - runway
		if adjacent_tile_coord.x < 0:
			if Tile.Dir.LEFT in current_connection_points:
				_add_single_barrier_to_tile(adjacent_tile_coord, Barrier.BarrierID.RIGHT)
		elif adjacent_tile_coord.x >= GRID_WIDTH:
			if Tile.Dir.RIGHT in current_connection_points:
				_add_single_barrier_to_tile(adjacent_tile_coord, Barrier.BarrierID.LEFT)
		elif adjacent_tile_coord.y >= GRID_HEIGHT:
			if Tile.Dir.DOWN in current_connection_points:
				_add_single_barrier_to_tile(adjacent_tile_coord, Barrier.BarrierID.UP)
		elif adjacent_tile_coord.y == -1 and adjacent_tile_coord.x % 2 != 0:
			if Tile.Dir.UP not in current_connection_points:
				_add_single_barrier_to_tile(adjacent_tile_coord, Barrier.BarrierID.DOWN)
		elif adjacent_tile_coord.y == -1 and adjacent_tile_coord.x % 2 == 0:
			if Tile.Dir.UP in current_connection_points:
				_add_single_barrier_to_tile(adjacent_tile_coord, Barrier.BarrierID.DOWN)
		return  # Early return so as to not handle out of bounds
	
	""" 
	Two logical passes required here:
	First, check if there is a connection point on the adjacent tile and none
	on the current tiles connection point. If so, add barrier to the current tile

	Then, check if there is a connection point on the current tile and none on the
	adjacent tile. If so, add barrier to the adjacent tile

	During these checks, we will also check if the barrier exists and remove if it is not required
	At startup, this will repeat work, but it will useful later in the game
	"""
	
	var adjacent_connection_points: Array[int] = _flatten_connection_points(Tile.TILE_ENTRY_EXIT_PAIRS[adjacent_tile_ref.tile_id])
	# Remove any existing barriers in these relevant positions
	var current_tile_barriers = barriers_reference[current_tile_coord]
	var new_current_barriers = []
	for current_tile_barrier in current_tile_barriers:
		if current_tile_barrier.barrier_id != current_tile_connection_point:
			new_current_barriers.append(current_tile_barrier)
		else:
			current_tile_barrier.queue_free()
	barriers_reference[current_tile_coord] = new_current_barriers
		
	var adjacent_tile_barriers = barriers_reference.get(adjacent_tile_coord)
	var new_adjacent_barriers = []
	for adjacent_barrier in adjacent_tile_barriers:
		if adjacent_barrier.barrier_id != adjacent_target_connection_point:
			new_adjacent_barriers.append(adjacent_barrier)
		else:
			adjacent_barrier.queue_free()
	barriers_reference[adjacent_tile_coord] = new_adjacent_barriers
	
	if current_tile_connection_point not in current_connection_points and adjacent_target_connection_point in adjacent_connection_points:
		# Make barrier on current tile
		_add_single_barrier_to_tile(current_tile_coord, current_tile_connection_point)

	if current_tile_connection_point in current_connection_points and adjacent_target_connection_point not in adjacent_connection_points:
		_add_single_barrier_to_tile(adjacent_tile_coord, adjacent_target_connection_point)


func _update_barriers_for_tile(tile_pos: Vector2i) -> void:
	var up_tile_pos = Vector2i(tile_pos.x, tile_pos.y - 1)
	var down_tile_pos = Vector2i(tile_pos.x, tile_pos.y + 1)
	var left_tile_pos = Vector2i(tile_pos.x - 1, tile_pos.y)
	var right_tile_pos = Vector2i(tile_pos.x + 1, tile_pos.y)

	_resolve_barrier_to_tile(tile_pos, Tile.Dir.UP, up_tile_pos, Tile.Dir.DOWN)
	_resolve_barrier_to_tile(tile_pos, Tile.Dir.LEFT, left_tile_pos, Tile.Dir.RIGHT)
	_resolve_barrier_to_tile(tile_pos, Tile.Dir.DOWN, down_tile_pos, Tile.Dir.UP)
	_resolve_barrier_to_tile(tile_pos, Tile.Dir.RIGHT, right_tile_pos, Tile.Dir.LEFT)


func _create_barriers() -> void:
	for barrier_list in barriers_reference.values():
		for barrier_ref in barrier_list:
			barrier_ref.queue_free()
	for tile_pos in tiles_reference.keys():
		barriers_reference[tile_pos] = []
	for tile_pos in tiles_reference.keys():
		_update_barriers_for_tile(tile_pos)
	# Special case for invisible barrier in runway
	for x in range(GRID_WIDTH):
		_add_single_barrier_to_tile(Vector2i(x, -4), Barrier.BarrierID.DOWN, true)


func _create_train_timer() -> void: 
	train_step_timer.connect("timeout", _on_train_step)
	train_step_timer.wait_time = GameControl.train_step_time
	train_step_timer.one_shot = false
	train_step_timer.autostart = true
	add_child(train_step_timer)
	
	speedup_cooldown_timer.connect("timeout", _on_speedup_cooldown_timer)
	speedup_cooldown_timer.wait_time = speedup_cooldown_time
	speedup_cooldown_timer.one_shot = true
	speedup_cooldown_timer.autostart = false
	add_child(speedup_cooldown_timer)


func _on_tile_rotated(tile_coord: Vector2i, _tile_reference: Tile, _new_tile_id: Tile.TileID) -> void:
	_update_barriers_for_tile(tile_coord)


# Game progress stuff
func spawn_train(runway_choice: int = -1) -> void:
	if runway_choice == -1:  # Invalid default
		runway_choice = available_runways[randi() % available_runways.size()]
	var new_train: Train = TRAIN_SCENE.instantiate()
	new_train.game_board_reference = self
	trains.add_child(new_train)
	var new_train_coord: Vector2i = Vector2i(2 * runway_choice - 1,  -(RUNWAY_LENGTH + 1))
	new_train.generate_train(new_train_coord)


func _on_train_step() -> void:
	for each_train in trains.get_children():
		each_train.move_to_next()


func _on_speedup_cooldown_timer() -> void:
	speedup_cooldown_active = false


func _on_level_reached() -> void:
	train_step_timer.time = GameControl.train_step_time
	_restart_step_timer()


func _disable_runway(runway_to_disable: int, x_coord: int) -> void:
	if runway_to_disable not in available_runways:  # Already cleared
		return
	available_runways.erase(runway_to_disable)
	var runway_ref: Tile
	for y in range(0, -RUNWAY_LENGTH -1, -1):
		runway_ref = tiles_reference.get(Vector2i(x_coord, y))
		if runway_ref != null:
			if runway_ref.has_tunnel:
				runway_ref.disable_tunnel()
	
	if len(available_runways) == 0:
		SignalBus.emit_signal("game_lost")


func spawn_powerup() -> void:
	# Roll for powerup
	var powerups_to_clear: Array = []
	for powerup_coord in powerups_reference.keys():
		var freed = powerups_reference[powerup_coord].increment_turn()
		if freed:
			powerups_to_clear.append(powerup_coord)
	
	for powerup_coord in powerups_to_clear:
		powerups_reference.erase(powerup_coord)
	
	var new_powerup_id = _select_random_powerup()
	if new_powerup_id != Powerup.PowerupID.NONE:
		var new_powerup = POWERUP_SCENE.instantiate()
		powerups.add_child(new_powerup)
		new_powerup.set_powerup(new_powerup_id)
		new_powerup.game_board_reference = self
		
		# Select random point
		var spawn_coord: Vector2i = Vector2i(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
		while spawn_coord in powerups_reference:
			spawn_coord = Vector2i(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
			
		var spawn_point = Vector2i(GRID_START_X + GRID_SIZE * spawn_coord.x, GRID_START_Y + GRID_SIZE * spawn_coord.y)
		new_powerup.global_position = spawn_point
		powerups_reference[spawn_coord] = new_powerup


func _on_train_converted_to_blocks(new_block_positions: Array[Vector2i], block_colour: Color) -> void:
	for block_coord in new_block_positions:
		var runway_of_block = ceil(float(block_coord.x) / 2.0)
		var tile_to_convert = tiles_reference.get(block_coord)
		if block_coord.y < 0:
			# Runway disabled
			_disable_runway(runway_of_block, block_coord.x)
			continue
		tile_to_convert.convert_to_block(block_colour)
		_update_barriers_for_tile(block_coord)
		speedup_cooldown_timer.start()
		speedup_cooldown_active = true
	_attempt_clear()


func is_barriers_at_tile_in_direction(tile_pos: Vector2i, direction: Tile.Dir) -> bool:
	var barrier_tile: Vector2i = tile_pos + Tile.DIR_TO_VECTOR[direction]
	var barrier_ids: Array[Tile.Dir] = []
	for barrier_ref in barriers_reference[barrier_tile]:
		barrier_ids.append(barrier_ref.barrier_id)
	return Tile.OPPOSITE_DIRS[direction] in barrier_ids


func _get_global_position_from_grid_coord(grid_coord: Vector2i) -> Vector2i:
	return Vector2i(GRID_START_X + grid_coord.x * GRID_SIZE, GRID_START_Y + grid_coord.y * GRID_SIZE)


func _regenerate_board() -> void:
	const TILE_MOVE_DELAY = 0.05
	# From bottom row, iterate upwards to both:
	# logically move the reference down and
	# physically move the Tile object down (with animation called on reference)

	# Using rows_to_clear...
	var num_rows_to_drop = 0  # Increment this bottom-up
	var rows_to_drop_required: Dictionary = {}
	
	for y in range(GRID_HEIGHT - 1, -1, -1):
		rows_to_drop_required[y] = num_rows_to_drop
		if y in rows_to_clear:
			num_rows_to_drop += 1
			continue

	# Now plan the moves and move them
	var moves: Dictionary = {}  # Moves for planning
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if y in rows_to_clear:
				continue  # Nothing to move
			var old_coord = Vector2i(x, y)
			var new_coord = Vector2i(x, y + rows_to_drop_required[y])
			if old_coord == new_coord:
				continue  # No move to make

			var tile_ref: Tile = tiles_reference.get(Vector2i(x, y))
			moves[tile_ref] = [new_coord, x, old_coord]
			
	for tile_ref in moves.keys():
		tiles_reference[moves[tile_ref][0]] = tile_ref
		var new_global_pos: Vector2i = _get_global_position_from_grid_coord(moves[tile_ref][0])
		tile_ref.animate_to_location(new_global_pos, TILE_MOVE_DELAY * moves[tile_ref][1], moves[tile_ref][0])
		for barrier_ref in barriers_reference[moves[tile_ref][2]]:
			barrier_ref.animate_to_location(new_global_pos, TILE_MOVE_DELAY * moves[tile_ref][1])

	# Spawn new tiles at the top
	for y in range(num_rows_to_drop):
		for x in range(GRID_WIDTH):
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = Vector2(GRID_START_X + x * GRID_SIZE, TILE_SPAWN_START.y - GRID_SIZE * num_rows_to_drop + y * GRID_SIZE)
			tiles.add_child(new_tile)
			new_tile.set_tile(_select_random_tile())
			var new_tile_coord: Vector2i = Vector2i(x, y)
			var new_tile_position = _get_global_position_from_grid_coord(new_tile_coord)
			new_tile.animate_to_location(new_tile_position, TILE_MOVE_DELAY * x, new_tile_coord)
			tiles_reference[new_tile_coord] = new_tile
	
	# Rebuild all barriers
	_create_barriers()
	
	# Reset all tile selectability for safety
	for tile_ref in tiles_reference.values():
		tile_ref.set_is_selected(false)
	current_active_tile = tiles_reference[Vector2i(0, 0)]
	current_active_tile.set_is_selected(true)


func clear_row(row: int) -> void:
	for x in GRID_WIDTH:
		tiles_reference[Vector2i(x, row)].clear_tile()
		tiles_reference.erase(Vector2i(x, row))


func _attempt_clear() -> void:
	print("ATTEMPTING CLEAR")
	rows_to_clear = []
	var clearable_row: bool
	for y in range(GRID_HEIGHT):
		clearable_row = true  # Assume true and go false
		for x in range(GRID_WIDTH):
			if tiles_reference[Vector2i(x, y)].tile_id != Tile.TileID.BLOCK:
				clearable_row = false
		if clearable_row:
			rows_to_clear.append(y)
	
	print("CLEARABLE ROWS " + str(rows_to_clear))
	
	if len(rows_to_clear) > 0:
		for row in rows_to_clear:
			clear_row(row)
		SignalBus.emit_signal("rows_cleared", len(rows_to_clear), modifiers)
		_regenerate_board()
	if not GameControl.game_lost:
		spawn_powerup()
		spawn_train()
