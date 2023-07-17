class_name GameBoard extends Node2D

const TILE_SCENE: PackedScene = preload("res://main/tiles/tile.tscn")
const BARRIER_SCENE: PackedScene = preload("res://main/tiles/barrier.tscn")
const TRAIN_SCENE: PackedScene = preload("res://main/trains/train.tscn")

const BASE_RES_X = 480
const BASE_RES_Y = 640
const SCREEN_SCALING_FACTOR: float = 1.75

const GRID_SIZE: int = 16
const GRID_WIDTH: int = 9
const GRID_HEIGHT: int = 15
const GRID_START_X: int = int((BASE_RES_X / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_WIDTH) / 2)

const RUNWAY_LENGTH: int = 5
const NUM_RUNWAYS: int = (GRID_WIDTH - 1) / 2
const YOFFSET: int = RUNWAY_LENGTH * GRID_SIZE
const GRID_START_Y: int = int(((BASE_RES_Y + YOFFSET) / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_HEIGHT) / 2)

@onready var playable_area: NinePatchRect = $playable_area
@onready var tiles: Node2D = $tiles
@onready var barriers: Node2D = $barriers
@onready var trains: Node2D = $trains
@onready var runway: Node2D = $runway
@onready var tile_cursor: Sprite2D = $tile_cursor
@onready var blocks: Node2D = $blocks

var new_tile: Tile
var current_active_tile: Tile

var tiles_reference: Dictionary = {}
var barriers_reference: Dictionary = {}

var train_step_timer: Timer = Timer.new()

func _ready() -> void:
	randomize()
	_create_playable_area()
	_create_board()
	_create_barriers()
	# Set cursor
	tile_cursor.initialise_cursor()
	current_active_tile = tiles_reference[Vector2i(0, GRID_HEIGHT - 1)]
	current_active_tile.set_is_selected(true)
	SignalBus.connect("tile_rotated", _on_tile_rotated)
	spawn_train()
	_create_train_timer()


func _process(_delta: float) -> void:
	if GameControl.game_active:
		if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_up"):
			var vert_move = Input.get_axis("move_up", "move_down")
			var horiz_move = Input.get_axis("move_left", "move_right")
			var new_grid_position: Vector2i
			new_grid_position = tile_cursor.move_cursor_grid_with_animate(Vector2i(horiz_move, vert_move))
			
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


func _create_board() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = Vector2(GRID_START_X + x * GRID_SIZE, GRID_START_Y + y * GRID_SIZE)
			tiles.add_child(new_tile)
			var new_tile_coord: Vector2i = Vector2i(x, y)
			tiles_reference[new_tile_coord] = new_tile
			new_tile.set_tile_coord(new_tile_coord)
			barriers_reference[new_tile_coord] = []
	
	# Then carefully randomise the board
	# Not too many of one type, more of the basic types. No empties initially
	
	const selection_weights: Dictionary = {
		Tile.TileID.VERT: 1.0,
		Tile.TileID.HORIZ: 1.0,
		Tile.TileID.CROSS: 0.2,
		Tile.TileID.LEFT_UP: 0.9,
		Tile.TileID.RIGHT_UP: 0.9,
		Tile.TileID.LEFT_DOWN: 0.9,
		Tile.TileID.RIGHT_DOWN: 0.9
	}
	
	var accumulated_weights: Dictionary = {}
	var tracked_weight = 0.0
	for tile_id in selection_weights.keys():
		tracked_weight += selection_weights[tile_id]
		accumulated_weights[tile_id] = tracked_weight
		
	var overall_weight = sum_array(selection_weights.values())
	# Weight initialisation complete!
	
	var roll: float
	for tile_ref in tiles_reference.values():
		roll = randf_range(0.0, overall_weight)
		
		for tile_id in accumulated_weights.keys():
			if accumulated_weights[tile_id] > roll:
				tile_ref.set_tile(tile_id)
				break

	# Add in runway
	var runway_pos: Vector2i
	var runway_y_offset = GRID_START_Y - (RUNWAY_LENGTH - 1) * GRID_SIZE
	for x in range(1, GRID_WIDTH, 2):
		for y in range(RUNWAY_LENGTH - 1):
			runway_pos = Vector2i(GRID_START_X + x * GRID_SIZE, runway_y_offset + y * GRID_SIZE)
			new_tile = TILE_SCENE.instantiate()
			new_tile.global_position = runway_pos
			runway.add_child(new_tile)
			new_tile.set_tile(Tile.TileID.VERT)


func _flatten_connection_points(input_array: Array) -> Array[int]:
	var output_array: Array[int] = []
	for element in input_array:
		if element is Array:
			output_array += _flatten_connection_points(element)
		else:
			output_array.append(element)
	return output_array


func _add_single_barrier_to_tile(tile_id: Vector2i, barrier_id: int) -> void:
	var new_barrier = BARRIER_SCENE.instantiate()
	new_barrier.global_position = Vector2(GRID_START_X + tile_id.x * GRID_SIZE, GRID_START_Y + tile_id.y * GRID_SIZE)
	barriers.add_child(new_barrier)
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
		elif adjacent_tile_coord.y < 0 and adjacent_tile_coord.x % 2 != 0:
			if Tile.Dir.UP not in current_connection_points:
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
	for tile_pos in tiles_reference.keys():
		_update_barriers_for_tile(tile_pos)


func _create_train_timer() -> void: 
	train_step_timer.connect("timeout", _on_train_step)
	train_step_timer.wait_time = GameControl.train_step_timer
	train_step_timer.one_shot = false
	train_step_timer.autostart = true
	add_child(train_step_timer)


func _on_tile_rotated(tile_coord: Vector2i, tile_reference: Tile, new_tile_id: Tile.TileID) -> void:
	_update_barriers_for_tile(tile_coord)


# Game progress stuff
func spawn_train() -> void:
	var runway_choice: int = randi_range(1, NUM_RUNWAYS)
	var new_train: Train = TRAIN_SCENE.instantiate()
	new_train.game_board_reference = self
	trains.add_child(new_train)
	var new_train_coord: Vector2i = Vector2i(2 * runway_choice - 1,  -(RUNWAY_LENGTH + 1))
	new_train.generate_train(new_train_coord)


func _on_train_step() -> void:
	for each_train in trains.get_children():
		each_train.move_to_next()
		print("TRAIN UPDATE")
