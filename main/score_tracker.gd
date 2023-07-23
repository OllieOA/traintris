class_name ScoreTracker extends Resource

@export var score_data: Dictionary = {}


func set_best_score(val: int) -> void:
	score_data["best_score"] = val


func set_best_level(val: int) -> void:
	score_data["best_level"] = val

