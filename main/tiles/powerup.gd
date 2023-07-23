class_name Powerup extends Node2D

enum PowerupID {NUKE, PIKE, SPREAD, MULTIPLIER, NONE}
var powerup_id: PowerupID = PowerupID.NONE

var turns_until_despawn: float = 4
var powerup_coord: Vector2i
var game_board_reference: GameBoard
@onready var bob: AnimationPlayer = $powerup_sprite/bob
@onready var powerup_sprite: Sprite2D = $powerup_sprite
@onready var nuke: AudioStreamPlayer = $nuke
@onready var pike: AudioStreamPlayer = $pike
@onready var spread: AudioStreamPlayer = $spread


func _ready() -> void:
	bob.play("bob")


func set_powerup(new_powerup_id: PowerupID) -> void:
	powerup_id = new_powerup_id
	powerup_sprite.frame = new_powerup_id


func _fade() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.4)
	bob.speed_scale = 2


func increment_turn() -> bool:
	turns_until_despawn -= 1
	if turns_until_despawn == 1:
		_fade()
	elif turns_until_despawn == 0:
		queue_free()
		return true
	return false


func apply_powerup(train_ref: Train) -> void:
	match powerup_id:
		PowerupID.NUKE:
			for tile_coord in game_board_reference.tiles_reference.keys():
				if tile_coord.y < 0:
					continue
				if game_board_reference.tiles_reference[tile_coord].tile_id != Tile.TileID.BLOCK:
					game_board_reference.tiles_reference[tile_coord].convert_to_block(train_ref.train_colour)
			train_ref.remove_from_map()
			nuke.play()
			game_board_reference._attempt_clear()
		
		PowerupID.PIKE:
			var train_coord = train_ref.segments_refs[0].get_current_grid_location()
			for y in range(train_coord.y, GameBoard.GRID_HEIGHT):
				if game_board_reference.tiles_reference[Vector2i(train_coord.x, y)].tile_id != Tile.TileID.BLOCK:
					game_board_reference.tiles_reference[Vector2i(train_coord.x, y)].convert_to_block(train_ref.train_colour)
			train_ref.remove_from_map()
			pike.play()
			game_board_reference._attempt_clear()
		
		PowerupID.SPREAD:
			var train_coord = train_ref.segments_refs[0].get_current_grid_location()
			for y in range(train_coord.y-1, train_coord.y+2):
				for x in range(GameBoard.GRID_WIDTH):
					if y < 0:
						continue
					if game_board_reference.tiles_reference[Vector2i(x, y)].tile_id != Tile.TileID.BLOCK:
						game_board_reference.tiles_reference[Vector2i(x, y)].convert_to_block(train_ref.train_colour)
						game_board_reference._update_barriers_for_tile(Vector2i(x, y))
			train_ref.remove_from_map()
			spread.play()
			game_board_reference._attempt_clear()
			
		PowerupID.MULTIPLIER:
			game_board_reference.add_modifier({"modifier_operation": "*", "modifier_value": 3})
	SignalBus.emit_signal("freed_powerup", self)
	queue_free()
  
