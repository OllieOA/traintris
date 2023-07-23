class_name Barrier extends Node2D

enum BarrierID {LEFT, DOWN, RIGHT, UP}

var barrier_id: BarrierID : set = set_barrier_id

@onready var barrier_sprite: Sprite2D = $barrier_sprite


func animate_to_location(new_location: Vector2, delay: float) -> void:
	var transition_duration: float = 0.1
	var move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "global_position", new_location, transition_duration).set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	move_tween.play()
	await move_tween.finished


func set_barrier_id(new_barrier_id) -> void:
	barrier_id = new_barrier_id
	barrier_sprite.frame = barrier_id


func hide_barrier() -> void:
	barrier_sprite.hide()
