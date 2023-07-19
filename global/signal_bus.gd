extends Node

signal tile_rotated(tile_coord: Vector2i, tile_reference: Tile, new_tile_id: int)
signal train_converted_to_blocks(new_blocks: Array[Vector2i], block_colour: Color)
