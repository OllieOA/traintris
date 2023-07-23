extends Control


@onready var start_game_button: Button = $start_game_container/start_game_organiser/start_game_button
@onready var settings_button: Button = $start_game_container/start_game_organiser/settings_button
@onready var how_to_play_button: Button = $start_game_container/start_game_organiser/how_to_play_button
@onready var best_level: Label = $start_game_container/start_game_organiser/best_level
@onready var best_score: Label = $start_game_container/start_game_organiser/best_score
@onready var how_to_play_panel: PanelContainer = $how_to_play_panel
@onready var settings_panel: PanelContainer = $settings_panel

const MAIN_GAME_SCENE: PackedScene = preload("res://main/main_level.tscn")


func _ready() -> void:
	start_game_button.connect("pressed", on_start_button_pressed)
	settings_button.connect("pressed", on_settings_button_pressed)
	how_to_play_button.connect("pressed", on_how_button_pressed)
	
	best_level.text = "HIGHEST LEVEL: " + str(GameScore.get_highest_level())
	best_score.text = "HIGHEST SCORE: " + str(GameScore.get_highest_score())


func on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_GAME_SCENE)


func on_settings_button_pressed() -> void:
	settings_panel.show()


func on_how_button_pressed() -> void:
	how_to_play_panel.show()
