extends CanvasLayer

@onready var score_panel: PanelContainer = $ScorePanel
@onready var level_value: Label = %LevelValue
@onready var total_score_value: Label = %TotalScoreValue
@onready var next_level_value: Label = %NextLevelValue
@onready var back_to_menu: Button = %BackToMenu
@onready var game_over: PanelContainer = $GameOver
@onready var praise: Label = $GameOver/GameOverContainer/GameOverOrganiser/Praise

const MENU_SCENE = preload("res://ui/title_screen.tscn")

func _ready() -> void:
	GameScore.connect("score_updated", update_scores)
	SignalBus.connect("game_lost", on_game_lost)
	back_to_menu.connect("pressed", _on_menu_pressed)
	update_scores()


func update_scores() -> void:
	level_value.text = str(GameScore.current_level + 1)
	total_score_value.text = str(GameScore.current_score)
	if GameScore.current_level < GameScore.RATIO_POINTS_FOR_LEVEL.keys().max():
		next_level_value.text = str(GameScore.score_for_next_level)
	else:
		next_level_value.text = "SURVIVE"


func on_game_lost() -> void:
	score_panel.hide()
	game_over.show()
	praise.text = "GREAT WORK!\nYOU SURVIVED %s LEVELS\nWITH %s POINTS!\n\nTHANK YOU FOR PLAYING!\nEVERYTHING BY OLLIEBOYOA" % [GameScore.current_level, GameScore.current_score]


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_packed(MENU_SCENE)
