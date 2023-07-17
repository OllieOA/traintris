class_name Tile extends Node2D

# This enum sets up the names in order of the frames in the sprite
enum TileID {VERT, RIGHT_UP, LEFT_DOWN, HORIZ, LEFT_UP, RIGHT_DOWN, CROSS, EMPTY, BLOCK}

# Helpers for direction consistency
enum Dir {LEFT, DOWN, RIGHT, UP}
enum Rot {CLOCKWISE, ANTICLOCKWISE}

const OPPOSITE_DIRS: Dictionary = {
	Dir.LEFT: Dir.RIGHT,
	Dir.RIGHT: Dir.LEFT,
	Dir.UP: Dir.DOWN,
	Dir.DOWN: Dir.UP
}

const TILE_ENTRY_EXIT_PAIRS: Dictionary = {
	TileID.VERT: [[Dir.UP, Dir.DOWN]],
	TileID.RIGHT_UP: [[Dir.RIGHT, Dir.UP]],
	TileID.LEFT_DOWN: [[Dir.LEFT, Dir.DOWN]],
	TileID.HORIZ: [[Dir.LEFT, Dir.RIGHT]],
	TileID.LEFT_UP: [[Dir.LEFT, Dir.UP]],
	TileID.RIGHT_DOWN: [[Dir.RIGHT, Dir.DOWN]],
	TileID.CROSS: [[Dir.RIGHT, Dir.LEFT], [Dir.UP, Dir.DOWN]],
	TileID.EMPTY: [],  # Should not be reachable
	TileID.BLOCK: []
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
var tile_coord: Vector2i : set = set_tile_coord, get = get_tile_coord

var is_rotatable: bool = false : set = set_is_rotatable, get = get_is_rotatable
var is_selected: bool = false : set = set_is_selected

@onready var tile_sprite: Sprite2D = $tile_sprite
@onready var block_sprite: Sprite2D = $block_sprite

func _ready():
	tile_id = tile_sprite.frame


func _process(_delta: float) -> void:
	if not is_selected:
		return

	if Input.is_action_just_pressed("rotate_anticlockwise"):
		rotate_tilewise(Rot.ANTICLOCKWISE)
	
	elif Input.is_action_just_pressed("rotate_clockwise"):
		rotate_tilewise(Rot.CLOCKWISE)
	


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
	
	SignalBus.emit_signal("tile_rotated", tile_coord, self, tile_id)
	
	return true


func convert_to_block(target_color: Color) -> void:
	tile_sprite.hide()
	block_sprite.show()
	block_sprite.modulate = target_color
	set_is_rotatable(false)


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


func set_tile_coord(new_tile_coord: Vector2i) -> void:
	tile_coord = new_tile_coord


func get_tile_coord() -> Vector2i:
	return tile_coord
