class_name Tile extends Node2D

# This enum sets up the names in order of the frames in the sprite
enum TileID {VERT, RIGHT_UP, LEFT_DOWN, HORIZ, LEFT_UP, RIGHT_DOWN, CROSS, EMPTY}

# Helpers for direction consistency
enum Dir {UP, DOWN, LEFT, RIGHT}
enum Rot {CLOCKWISE, ANTICLOCKWISE}

const TILE_ENTRY_EXIT_PAIRS: Dictionary = {
	TileID.VERT: [[Dir.UP, Dir.DOWN]],
	TileID.RIGHT_UP: [[Dir.RIGHT, Dir.UP]],
	TileID.LEFT_DOWN: [[Dir.LEFT, Dir.DOWN]],
	TileID.HORIZ: [[Dir.LEFT, Dir.RIGHT]],
	TileID.LEFT_UP: [[Dir.LEFT, Dir.UP]],
	TileID.RIGHT_DOWN: [[Dir.RIGHT, Dir.DOWN]],
	TileID.CROSS: [[Dir.RIGHT, Dir.LEFT], [Dir.UP, Dir.DOWN]],
	TileID.EMPTY: []  # Should not be reachable
}

const CLOCKWISE_ROTATION_DEFINITIONS: Dictionary = {
	TileID.VERT: TileID.HORIZ,
	TileID.HORIZ: TileID.VERT,
	TileID.CROSS: TileID.CROSS,
	TileID.EMPTY: TileID.EMPTY,
	TileID.RIGHT_UP: TileID.RIGHT_DOWN,
	TileID.LEFT_DOWN: TileID.LEFT_UP,
	TileID.LEFT_UP: TileID.RIGHT_UP,
	TileID.RIGHT_DOWN: TileID.LEFT_DOWN
}

const ANTICLOCKWISE_ROTATION_DEFINITIONS: Dictionary = {
	TileID.VERT: TileID.HORIZ,
	TileID.HORIZ: TileID.VERT,
	TileID.CROSS: TileID.CROSS,
	TileID.EMPTY: TileID.EMPTY,
	TileID.RIGHT_UP: TileID.LEFT_UP,
	TileID.LEFT_DOWN: TileID.RIGHT_DOWN,
	TileID.LEFT_UP: TileID.LEFT_DOWN,
	TileID.RIGHT_DOWN: TileID.RIGHT_UP
}

var tile_id: TileID : set = set_tile, get = get_tile

var is_rotatable: bool = false : set = set_is_rotatable, get = get_is_rotatable
var is_selected: bool = false : set = set_is_selected

@onready var tile_sprite: Sprite2D = $tile_sprite

func _ready():
	tile_id = tile_sprite.frame


func rotate_tilewise(direction: int) -> bool:
	var next_rot_lookup: Dictionary
	match direction:
		Rot.ANTICLOCKWISE:
			next_rot_lookup = ANTICLOCKWISE_ROTATION_DEFINITIONS
		Rot.CLOCKWISE:
			next_rot_lookup = CLOCKWISE_ROTATION_DEFINITIONS
		_:
			print("CANNOT ROTATE - DID NOT UNDERSTAND " + str(direction))
			return false
	
	var next_tile: TileID = next_rot_lookup[tile_id]
	tile_id = next_tile
	tile_sprite.frame = tile_id
	
	return true


# Catch input
func _unhandled_input(event: InputEvent) -> void:
	if not is_selected:
		return


	if event.is_action_pressed("rotate_anticlockwise"):
		print("ROTATING ANTICLOCKWISE")
		rotate_tilewise(Rot.ANTICLOCKWISE)
	
	elif event.is_action_pressed("rotate_clockwise"):
		print("ROTATING CLOCKWISE")
		rotate_tilewise(Rot.CLOCKWISE)


# Flag setters and getters
func set_is_rotatable(val: bool) -> void:
	is_rotatable = val


func get_is_rotatable() -> bool:
	return is_rotatable


func set_is_selected(val: bool) -> void:
	is_selected = val


func set_tile(new_tile_id: TileID) -> void:
	if new_tile_id not in TileID.values():
		print("CANNOT SET TO " + str(new_tile_id))
		return

	tile_id = new_tile_id
	tile_sprite.frame = new_tile_id


func get_tile() -> TileID:
	return tile_id
