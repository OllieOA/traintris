class_name Train extends Node2D

enum TrainColour {
	RED,
	BLUE,
	GREEN,
	YELLOW
}

const COLOUR_LOOKUP: Dictionary = {
	TrainColour.RED: Color.DARK_RED,
	TrainColour.BLUE: Color.SKY_BLUE,
	TrainColour.GREEN: Color.LIME_GREEN,
	TrainColour.YELLOW: Color.YELLOW
}

const TRAIN_SEGMENT_SCENE: PackedScene = preload("res://main/trains/train_segment.tscn")

var train_speed: float = 100.0

var num_carriages: int
var carriage_refs: Array[TrainSegment]

func _ready() -> void:
	num_carriages = randi_range(2, 5)


func _generate_train(base_position: Vector2i) -> void:
	var caboose_segment = TRAIN_SEGMENT_SCENE.instantiate()
	caboose_segment.global_position = base_position
	caboose_segment.is_caboose = true
	add_child(caboose_segment)
	carriage_refs.append(caboose_segment)
	
	var fuel_segment = TRAIN_SEGMENT_SCENE.instantiate()
	fuel_segment.global_position = base_position - Vector2i(0, GameBoard.GRID_SIZE)
	fuel_segment.is_fuel = true
	add_child(fuel_segment)
	carriage_refs.append(fuel_segment)
	
	var carriage_segment: TrainSegment
	for i in range(num_carriages):
		carriage_segment = TRAIN_SEGMENT_SCENE.instantiate()
		carriage_segment.global_position = base_position - Vector2i(0, 2 + i * GameBoard.GRID_SIZE)
	
