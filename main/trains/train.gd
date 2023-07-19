class_name Train extends Node2D

const COLOUR_CHOICES: Array[Color] = [
	Color.RED,
	Color.SKY_BLUE,
	Color.MEDIUM_AQUAMARINE,
	Color.YELLOW
]

const TRAIN_SEGMENT_SCENE: PackedScene = preload("res://main/trains/train_segment.tscn")
const TRAIN_DIRECTION_TO_VECTOR: Dictionary = {
	Tile.Dir.LEFT: Vector2i.LEFT,
	Tile.Dir.DOWN: Vector2i.DOWN,
	Tile.Dir.RIGHT: Vector2i.RIGHT,
	Tile.Dir.UP: Vector2i.UP,
}
const BLOCK_SCENE = preload("res://main/trains/block.tscn")

var train_colour
var caboose_grid_coord: Vector2i

var num_carriages: int
var segments_refs: Array[TrainSegment]

var game_board_reference: GameBoard


func _ready() -> void:
	num_carriages = randi_range(2, 5)


func generate_train(base_coord: Vector2i) -> void:
	train_colour = COLOUR_CHOICES[randi() % COLOUR_CHOICES.size()]
	var caboose_segment = TRAIN_SEGMENT_SCENE.instantiate()
	segments_refs.append(caboose_segment)
	caboose_segment.is_caboose = true
	add_child(caboose_segment)
	caboose_segment.set_train_colour(train_colour)
	
	var fuel_segment = TRAIN_SEGMENT_SCENE.instantiate()
	segments_refs.append(fuel_segment)
	fuel_segment.is_fuel = true
	add_child(fuel_segment)
	fuel_segment.set_train_colour(train_colour)
	
	var carriage_segment: TrainSegment
	for i in range(num_carriages):
		carriage_segment = TRAIN_SEGMENT_SCENE.instantiate()
		segments_refs.append(carriage_segment)
		carriage_segment.is_carriage = true
		add_child(carriage_segment)
		carriage_segment.set_train_colour(train_colour)
		
	# Initialise all segment's position and direction
	caboose_grid_coord = base_coord
	segments_refs[0].set_current_grid_location(caboose_grid_coord)
	segments_refs[0].set_previous_grid_location(caboose_grid_coord + Vector2i.UP)  # One down, always on initialisation
	segments_refs[0].set_current_train_direction(Tile.Dir.DOWN)
	segments_refs[0].set_previous_train_direction(Tile.Dir.DOWN)
	for i in range(1, len(segments_refs)):
		segments_refs[i].set_current_grid_location(segments_refs[i-1].get_current_grid_location() + Vector2i.UP)
		segments_refs[i].set_previous_grid_location(segments_refs[i].get_current_grid_location() + Vector2i.UP)
		segments_refs[i].set_current_train_direction(Tile.Dir.DOWN)
		segments_refs[i].set_previous_train_direction(Tile.Dir.DOWN)

	for ref in segments_refs:
		ref.move_to_current()


func _update_segment_ref_sprites(segment_ref: TrainSegment) -> void:
	if segment_ref.get_current_grid_location().y < 0:
		segment_ref.update_segment_sprite(Tile.Dir.UP, Tile.Dir.DOWN)
		return
	
	var exit_entry_pair = _get_direction_pair(
		Tile.OPPOSITE_DIRS[segment_ref.get_current_train_direction()], segment_ref.get_current_grid_location()
		)
	var entry_dir = exit_entry_pair[0]
	var exit_dir = exit_entry_pair[1]
	segment_ref.update_segment_sprite(entry_dir, exit_dir)


func update_caboose_grid_coord_logically(new_direction: Tile.Dir) -> void:
	# Logicially update every segment
	caboose_grid_coord = caboose_grid_coord + TRAIN_DIRECTION_TO_VECTOR[new_direction]
	segments_refs[0].set_previous_grid_location(segments_refs[0].get_current_grid_location())
	segments_refs[0].set_current_grid_location(caboose_grid_coord)
	
	segments_refs[0].set_previous_train_direction(segments_refs[0].get_current_train_direction())
	segments_refs[0].set_current_train_direction(new_direction)
	
	# Note here that direction is based on the direction after entering. 
	
	for i in range(1, len(segments_refs)):
		segments_refs[i].set_previous_grid_location(segments_refs[i].get_current_grid_location())
		segments_refs[i].set_current_grid_location(segments_refs[i-1].get_previous_grid_location())
		
		segments_refs[i].set_previous_train_direction(segments_refs[i].get_current_train_direction())
		segments_refs[i].set_current_train_direction(segments_refs[i-1].get_previous_train_direction())


func update_all_segments_physically() -> void:
	# Physically update every segment after logical updates
	for ref in segments_refs:
		ref.move_to_current()
		_update_segment_ref_sprites(ref)


func convert_train_to_blocks() -> void:
	var new_blocks: Array[Vector2i]
	for ref in segments_refs:
		var new_block = BLOCK_SCENE.instantiate()
		new_blocks.append(ref.get_current_grid_location())
		new_block.global_position = ref.global_position
		game_board_reference.blocks.add_child(new_block)
		new_block.modulate = train_colour
		ref.queue_free()
	SignalBus.emit_signal()


func _get_direction_pair(
	known_tile: Tile.Dir, grid_coord: Vector2i
	) -> Array[Tile.Dir]:
	var current_tile_id: Tile.TileID = game_board_reference.tiles_reference[grid_coord].tile_id
	var connection_points = Tile.TILE_ENTRY_EXIT_PAIRS[current_tile_id].duplicate()

	var operative_array: Array
	for connection_pair in connection_points:
		operative_array = connection_pair.duplicate()
		operative_array.erase(known_tile)
		if len(operative_array) == 1:  # We have identified the correct exit direction
			return [known_tile, operative_array[0]]
	
	return [Tile.Dir.NULL, Tile.Dir.NULL]


func move_to_next() -> void:
	# Check if next space is jammed
	# If so, convert to blocks
	# Otherwise, move caboose to next location, and iterate everything behind it
	# using update_caboose_grid_coord
	if caboose_grid_coord.y < 0:
		update_caboose_grid_coord_logically(Tile.Dir.DOWN)
		update_all_segments_physically()
		return
	
	var current_grid_coord = segments_refs[0].get_current_grid_location()
	var tile_entry_point = Tile.OPPOSITE_DIRS[segments_refs[0].get_current_train_direction()]
	var paired_points = _get_direction_pair(tile_entry_point, current_grid_coord)
	
	# Before updating physically, check if train is blocked by finding a barrier 
	# in the direction of the caboose
	
	update_caboose_grid_coord_logically(paired_points[1])
	if game_board_reference.is_barriers_at_tile_in_direction(
		segments_refs[0].get_previous_grid_location(), segments_refs[0].get_current_train_direction()
		):
		
		convert_train_to_blocks()
		queue_free()
		return
	print("MOVING TRAIN")
	update_all_segments_physically()
