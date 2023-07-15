class_name GameBoard extends Node2D

const TILE_SCENE: PackedScene = preload("res://main/tiles/tile.tscn")

const BASE_RES_X = 480
const BASE_RES_Y = 640
const SCREEN_SCALING_FACTOR: float = 1.75

const GRID_SIZE: int = 16
const GRID_WIDTH: int = 9
const GRID_HEIGHT: int = 16
const GRID_START_X: int = int((BASE_RES_X / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_WIDTH) / 2)

const RUNWAY_LENGTH: int = 5
const YOFFSET: int = RUNWAY_LENGTH * GRID_SIZE
const GRID_START_Y: int = int(((BASE_RES_Y + YOFFSET) / SCREEN_SCALING_FACTOR - GRID_SIZE * GRID_HEIGHT) / 2)

@onready var playable_area: NinePatchRect = $playable_area
@onready var tiles: Node2D = $tiles
@onready var runway: Node2D = $runway
@onready var tile_cursor: Sprite2D = $tile_cursor

var new_tile: Tile
var current_active_tile: Tile

var tiles_reference: Dictionary = {}

func _ready() -> void:
	randomize()
	_create_playable_area()
	_create_board()
	# Set cursor
	tile_cursor.initialise_cursor()
	current_active_tile = tiles_reference[Vector2i(0, GRID_HEIGHT - 1)]
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
			tiles_reference[Vector2i(x, y)] = new_tile
	
	# Then carefully randomise the board
	# Not too many of one type, more of the basic types. No empties initially
	
	const selection_weights: Dictionary = {
		Tile.TileID.VERT: 0.6,
		Tile.TileID.HORIZ: 0.6,
		Tile.TileID.CROSS: 0.2,
		Tile.TileID.LEFT_UP: 1.0,
		Tile.TileID.RIGHT_UP: 1.0,
		Tile.TileID.LEFT_DOWN: 1.0,
		Tile.TileID.RIGHT_DOWN: 1.0
	}
	
	var accumulated_weights: Dictionary = {}
	var tracked_weight = 0.0
	for tile_id in selection_weights.keys():
		tracked_weight += selection_weights[tile_id]
		accumulated_weights[tile_id] = tracked_weight
		
	var overall_weight = sum_array(selection_weights.values())
	
	# Weight initialisation complete!
	
	# This assumed ordered dictionaries!
	var roll: float
	for tile_ref in tiles_reference.values():
		roll = randf_range(0.0, overall_weight)
		
		for tile_id in accumulated_weights.keys():
			if accumulated_weights[tile_id] > roll:
				tile_ref.set_tile(tile_id)
				break
	
	# Add in barriers
	
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


func _unhandled_input(event: InputEvent) -> void:
	if GameControl.game_active:
		var vert_move = Input.get_axis("move_up", "move_down")
		var horiz_move = Input.get_axis("move_left", "move_right")
		var new_grid_position: Vector2i
		if abs(vert_move) != 0:  # Prioritise vertical
			new_grid_position = tile_cursor.move_cursor_grid_with_animate(Vector2i(0, vert_move))
		elif abs(horiz_move) != 0.0:
			new_grid_position = tile_cursor.move_cursor_grid_with_animate(Vector2i(horiz_move, 0))
		else:
			return
		
		current_active_tile.set_is_selected(false)
		current_active_tile = tiles_reference[new_grid_position]
		current_active_tile.set_is_selected(true)
