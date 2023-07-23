class_name Train extends Node2D

const COLOUR_CHOICES: Array[Color] = [
	Color.RED,
	Color.SKY_BLUE,
	Color.MEDIUM_AQUAMARINE,
	Color.YELLOW,
	Color.CORAL,
	Color.MEDIUM_ORCHID,
	Color.WEB_GRAY,
	Color.DARK_SLATE_BLUE
]

const TRAIN_SEGMENT_SCENE: PackedScene = preload("res://main/trains/train_segment.tscn")
const TRAIN_DIRECTION_TO_VECTOR: Dictionary = {
	Tile.Dir.LEFT: Vector2i.LEFT,
	Tile.Dir.DOWN: Vector2i.DOWN,
	Tile.Dir.RIGHT: Vector2i.RIGHT,
	Tile.Dir.UP: Vector2i.UP,
}

const RUNWAY_THRESHOLD: int = -4

@onready var whistle: AudioStreamPlayer = $whistle
@onready var chugga: AudioStreamPlayer = $chugga

var train_colour
var caboose_grid_coord: Vector2i

var num_carriages: int
var segments_refs: Array[TrainSegment]

var game_board_reference: GameBoard
var base_chugga_len: float 
var current_train_step_time: float  


func _ready() -> void:
	current_train_step_time = GameControl.train_step_time
	num_carriages = randi_range(GameControl.min_train_length, GameControl.max_train_length)
	whistle.play()
	chugga.play()
	base_chugga_len = chugga.stream.get_length()
	GameScore.connect("level_reached", on_level_reached)
	set_audio_speed()


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
	if segment_ref.get_current_grid_location().y < RUNWAY_THRESHOLD:
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
	var new_block_positions: Array[Vector2i] = []
	var train_length = len(segments_refs)
	for ref in segments_refs:
		new_block_positions.append(ref.get_previous_grid_location())
		ref.queue_free()
	SignalBus.emit_signal("train_converted_to_blocks", new_block_positions, train_colour)
	GameScore.add_to_score(int(2 * train_length))


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


func remove_from_map():
	for segment in segments_refs:
		var relevant_tile = game_board_reference.tiles_reference.get(segment.get_current_grid_location())
		if relevant_tile == null:
			continue
		relevant_tile.set_is_rotatable(true)
		segment.queue_free()
	queue_free()


func move_to_next() -> void:
	set_audio_speed()
	# Check if next space is jammed
	# If so, convert to blocks
	# Otherwise, move caboose to next location, and iterate everything behind it
	# using update_caboose_grid_coord
	if caboose_grid_coord.y < RUNWAY_THRESHOLD:  # There will be an invisible barrier at -3
		update_caboose_grid_coord_logically(Tile.Dir.DOWN)
		update_all_segments_physically()
		chugga.play()
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
		
	# Also check if there is another train segment at that location (noting that we only want to check current, not previous)
	for s_idx in range(1, len(segments_refs)):
		if segments_refs[s_idx].get_current_grid_location() == segments_refs[0].get_current_grid_location():
			if not [Tile.TileID.RIGHT_SWITCHBACK, Tile.TileID.LEFT_SWITCHBACK].has(game_board_reference.tiles_reference[segments_refs[0].get_current_grid_location()].tile_id):
				convert_train_to_blocks()
				queue_free()
				return
	update_all_segments_physically()
	
	if segments_refs[0].get_current_grid_location() in game_board_reference.powerups_reference.keys():
		game_board_reference.powerups_reference[segments_refs[0].get_current_grid_location()].apply_powerup(self)
	
	# Make train-occupied tiles not selectable (if below the runway)
	if segments_refs[0].get_current_grid_location().y >= 0:
		game_board_reference.tiles_reference[segments_refs[0].get_current_grid_location()].set_is_rotatable(false)
	if segments_refs[-1].get_previous_grid_location().y >= 0:
		game_board_reference.tiles_reference[segments_refs[-1].get_previous_grid_location()].set_is_rotatable(true)
	chugga.play()


func set_audio_speed() -> void:
	chugga.pitch_scale = base_chugga_len / current_train_step_time


func on_level_reached(_next_level: int) -> void:
	set_audio_speed()
