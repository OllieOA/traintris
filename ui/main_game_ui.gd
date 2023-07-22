extends CanvasLayer

@onready var level_value: Label = %LevelValue
@onready var total_score_value: Label = %TotalScoreValue
@onready var next_level_value: Label = %NextLevelValue


func _ready() -> void:
	GameScore.connect("score_updated", update_scores)


func update_scores() -> void:
	pass
