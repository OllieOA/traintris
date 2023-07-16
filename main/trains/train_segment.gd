class_name TrainSegment extends Node2D

var is_caboose: bool = false
var is_fuel: bool = false
var is_carriage: bool = false

@onready var caboose_spritesheet_solid: Sprite2D = $caboose_spritesheet_solid
@onready var caboose_spritesheet_uncoloured: Sprite2D = $caboose_spritesheet_uncoloured
@onready var fuel_spritesheet_solid: Sprite2D = $fuel_spritesheet_solid
@onready var fuel_spritesheet_uncoloured: Sprite2D = $fuel_spritesheet_uncoloured
@onready var carriage_spritesheet_solid: Sprite2D = $carriage_spritesheet_solid
@onready var carriage_spritesheet_uncoloured: Sprite2D = $carriage_spritesheet_uncoloured

# TODO: Add animations to sprite sheets

func _ready() -> void:
	if is_caboose:
		caboose_spritesheet_solid.show()
		caboose_spritesheet_uncoloured.show()
		caboose_spritesheet_uncoloured.modulate = Train.TrainColour.RED
		
	elif is_fuel:
		fuel_spritesheet_solid.show()
		fuel_spritesheet_uncoloured.show()
		fuel_spritesheet_uncoloured.modulate = Train.TrainColour.RED
	else:
		carriage_spritesheet_solid.show()
		carriage_spritesheet_uncoloured.show()
		carriage_spritesheet_uncoloured.modulate = Train.TrainColour.RED

