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

var train_speed: float = 100.0
var caboose_grid_coord: Vector2i

var num_carriages: int
var segments_refs: Array[TrainSegment]

var game_board_reference: GameBoard


func _ready() -> void:
	num_carriages = randi_range(2, 5)


func generate_train(base_coord: Vector2i) -> void:
	var train_colour = COLOUR_CHOICES[randi() % COLOUR_CHOICES.size()]
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


func update_caboose_grid_coord(new_direction: Tile.Dir) -> void:
	# Logicially update every segment
	caboose_grid_coord = caboose_grid_coord + TRAIN_DIRECTION_TO_VECTOR[new_direction]
	segments_refs[0].set_previous_grid_location(segments_refs[0].get_current_grid_location())
	segments_refs[0].set_current_grid_location(caboose_grid_coord)
	
	segments_refs[0].set_previous_train_direction(segments_refs[0].get_current_train_direction())
	segments_refs[0].set_current_train_direction(new_direction)
	
	for i in range(1, len(segments_refs)):
		segments_refs[i].set_previous_grid_location(segments_refs[i].get_current_grid_location())
		segments_refs[i].set_current_grid_location(segments_refs[i-1].get_previous_grid_location())
		
		segments_refs[i].set_previous_train_direction(segments_refs[i].get_current_train_direction())
		segments_refs[i].set_current_train_direction(segments_refs[i-1].get_previous_train_direction())


	# Physically update every segment
	for ref in segments_refs:
		ref.move_to_current()

func convert_train_to_blocks() -> void:
	pass


func move_to_next() -> void:
	# Check if next space is jammed
	# If so, convert to blocks
	# Otherwise, move caboose to next location, and iterate everything behind it
	# using update_caboose_grid_coord
	if caboose_grid_coord.y < 0:
		update_caboose_grid_coord(Tile.Dir.DOWN)
		return
	
	var current_grid_coord = segments_refs[0].get_current_grid_location()
	var current_connection_point = Tile.OPPOSITE_DIRS[segments_refs[0].get_current_train_direction()]
	var current_tile_id: Tile.TileID = game_board_reference.tiles_reference[current_grid_coord].tile_id
	var connection_points = Tile.TILE_ENTRY_EXIT_PAIRS[current_tile_id].duplicate()

	var operative_array: Array
	for connection_pair in connection_points:
		operative_array = connection_pair.duplicate()
		operative_array.erase(current_connection_point)
		if len(operative_array) == 1:  # We have identified the correct exit direction
			update_caboose_grid_coord(operative_array[0])
			return
	
	pass
