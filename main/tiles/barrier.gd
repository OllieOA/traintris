class_name Barrier extends Node2D

enum BarrierID {LEFT, DOWN, RIGHT, UP}

var barrier_id: BarrierID : set = set_barrier_id

@onready var barrier_sprite: Sprite2D = $barrier_sprite


func set_barrier_id(new_barrier_id) -> void:
	barrier_id = new_barrier_id
	barrier_sprite.frame = barrier_id
