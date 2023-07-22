extends CanvasLayer

@onready var level_value: Label = %LevelValue
@onready var total_score_value: Label = %TotalScoreValue
@onready var next_level_value: Label = %NextLevelValue


func _ready() -> void:
	GameScore.connect("score_updated", update_scores)
	update_scores()


func update_scores() -> void:
	level_value.text = str(GameScore.current_level + 1)
	total_score_value.text = str(GameScore.current_score)
	if GameScore.current_level < GameScore.RATIO_POINTS_FOR_LEVEL.keys().max():
		next_level_value.text = str(GameScore.score_for_next_level)
	else:
		next_level_value.text = "SURVIVE"
