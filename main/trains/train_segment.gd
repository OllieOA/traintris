class_name TrainSegment extends Node2D

var is_caboose: bool = false
var is_fuel: bool = false
var is_carriage: bool = false
var train_colour: Color : set = set_train_colour
var current_train_direction: Tile.Dir : set = set_current_train_direction
var previous_train_direction: Tile.Dir : set = set_previous_train_direction

var previous_grid_location: Vector2i : set = set_previous_grid_location, get = get_previous_grid_location
var current_grid_location: Vector2i : set = set_current_grid_location, get = get_current_grid_location

@onready var caboose_spritesheet_solid: Sprite2D = $caboose_spritesheet_solid
@onready var caboose_spritesheet_uncoloured: Sprite2D = $caboose_spritesheet_uncoloured
@onready var fuel_spritesheet_solid: Sprite2D = $fuel_spritesheet_solid
@onready var fuel_spritesheet_uncoloured: Sprite2D = $fuel_spritesheet_uncoloured
@onready var carriage_spritesheet_solid: Sprite2D = $carriage_spritesheet_solid
@onready var carriage_spritesheet_uncoloured: Sprite2D = $carriage_spritesheet_uncoloured

# TODO: Add animations to sprite sheets
var active_sprites: Array[Sprite2D] = []

var segment_direction_to_spriteframe: Dictionary = {
	"%d%d" % [Tile.Dir.RIGHT, Tile.Dir.LEFT]: 0,
	"%d%d" % [Tile.Dir.UP, Tile.Dir.DOWN]: 1,
	"%d%d" % [Tile.Dir.LEFT, Tile.Dir.RIGHT]: 2,
	"%d%d" % [Tile.Dir.DOWN, Tile.Dir.UP]: 3,
	"%d%d" % [Tile.Dir.RIGHT, Tile.Dir.UP]: 4,
	"%d%d" % [Tile.Dir.UP, Tile.Dir.LEFT]: 5,
	"%d%d" % [Tile.Dir.LEFT, Tile.Dir.DOWN]: 6,
	"%d%d" % [Tile.Dir.DOWN, Tile.Dir.RIGHT]: 7,
	"%d%d" % [Tile.Dir.DOWN, Tile.Dir.LEFT]: 8,
	"%d%d" % [Tile.Dir.RIGHT, Tile.Dir.DOWN]: 9,
	"%d%d" % [Tile.Dir.UP, Tile.Dir.RIGHT]: 10,
	"%d%d" % [Tile.Dir.LEFT, Tile.Dir.UP]: 11,
			
}

func _ready() -> void:
	if is_caboose:
		caboose_spritesheet_solid.show()
		caboose_spritesheet_uncoloured.show()
		active_sprites += [caboose_spritesheet_solid, caboose_spritesheet_uncoloured]
	elif is_fuel:
		fuel_spritesheet_solid.show()
		fuel_spritesheet_uncoloured.show()
		active_sprites += [fuel_spritesheet_solid, fuel_spritesheet_uncoloured]
	else:
		carriage_spritesheet_solid.show()
		carriage_spritesheet_uncoloured.show()
		active_sprites += [carriage_spritesheet_solid, carriage_spritesheet_uncoloured]


func move_to_current() -> void:
	var new_x = GameBoard.GRID_START_X + GameBoard.GRID_SIZE * get_current_grid_location().x
	var new_y = GameBoard.GRID_START_Y + GameBoard.GRID_SIZE * get_current_grid_location().y
	position = Vector2i(new_x, new_y)


func update_segment_sprite(entry_location: Tile.Dir, exit_location: Tile.Dir) -> void:
	if entry_location == Tile.Dir.NULL:
		return
	var new_frame_key = "%d%d" % [entry_location, exit_location]
	for sprite in active_sprites:
		sprite.frame = segment_direction_to_spriteframe[new_frame_key]


func set_current_train_direction(new_direction: Tile.Dir) -> void:
	current_train_direction = new_direction


func get_current_train_direction() -> Tile.Dir:
	return current_train_direction


func set_previous_train_direction(new_direction: Tile.Dir) -> void:
	previous_train_direction = new_direction


func get_previous_train_direction() -> Tile.Dir:
	return previous_train_direction 


func set_train_colour(new_colour: Color) -> void:
	train_colour = new_colour
	active_sprites[1].modulate = train_colour


func set_previous_grid_location(new_grid_location: Vector2i) -> void:
	previous_grid_location = new_grid_location


func get_previous_grid_location() -> Vector2i:
	return previous_grid_location


func set_current_grid_location(new_grid_location: Vector2i) -> void:
	current_grid_location = new_grid_location


func get_current_grid_location() -> Vector2i:
	return current_grid_location
