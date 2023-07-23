extends Node
signal score_updated  # Trigger the UI to update
signal level_reached(next_level: int)

var current_score: int = 0
var current_level: int = 0
var score_for_next_level: int = 0

var score_tracker: Resource
@export var best_score: int = 0
@export var highest_level: int = 0

const EXPONENT_FACTOR: float = 0.05
const BASE_SCORE: int = 20
const BASE_PONTS_PER_LEVEL: int = 100
const SCORE_TRACKER_PATH = "user://score_tracker.tres"

const RATIO_POINTS_FOR_LEVEL: Dictionary = {
	0: 1,
	1: 1,
	2: 2,
	3: 2,
	4: 3,
	5: 4,
	6: 6,
	7: 8,
	8: 9,
	9: 10,
}

const TRAIN_LEN_FOR_LEVEL: Dictionary = {
	0: [3, 4],
	1: [3, 4],
	2: [4, 6],
	3: [4, 6],
	4: [4, 8],
	5: [4, 8],
	6: [6, 8],
	7: [6, 8],
	8: [6, 10],
	9: [6, 10],
}

const TRAIN_TIMER_FOR_LEVEL: Dictionary = {
	0: 2.0,
	1: 1.9,
	2: 1.8,
	3: 1.7,
	4: 1.6,
	5: 1.5,
	6: 1.4,
	7: 1.2,
	8: 1.0,
	9: 0.8,
}

func _ready() -> void:
	SignalBus.connect("rows_cleared", add_to_score_clear_rows)
	SignalBus.connect("game_lost", _update_best_scores)
	# TODO: Load score
	_setup_score()
	
	if FileAccess.file_exists(SCORE_TRACKER_PATH):
		score_tracker = ResourceLoader.load(SCORE_TRACKER_PATH)
	else:
		score_tracker = ScoreTracker.new()


func _setup_score() -> void:
	GameControl.min_train_length = TRAIN_LEN_FOR_LEVEL[current_level][0]
	GameControl.max_train_length = TRAIN_LEN_FOR_LEVEL[current_level][1]
	GameControl.train_step_time = TRAIN_TIMER_FOR_LEVEL[current_level]
	score_for_next_level = RATIO_POINTS_FOR_LEVEL[current_level] * BASE_PONTS_PER_LEVEL


func add_to_score(val: int) -> void:
	current_score += val
	_check_next_level()
	emit_signal("score_updated")


func save_score() -> void:
	ResourceSaver.save(score_tracker, SCORE_TRACKER_PATH)


func _check_next_level() -> void:
	if current_score >= score_for_next_level:
		current_level = clamp(current_level + 1, RATIO_POINTS_FOR_LEVEL.keys().min(), RATIO_POINTS_FOR_LEVEL.keys().max())
		GameControl.train_step_time = TRAIN_TIMER_FOR_LEVEL[current_level]
		GameControl.min_train_length = TRAIN_LEN_FOR_LEVEL[current_level][0]
		GameControl.max_train_length = TRAIN_LEN_FOR_LEVEL[current_level][1]
		if current_level == RATIO_POINTS_FOR_LEVEL.keys().max():
			score_for_next_level = INF
			return
		score_for_next_level = 0
		for n in range(current_level + 1):
			score_for_next_level += RATIO_POINTS_FOR_LEVEL[n] * BASE_PONTS_PER_LEVEL
		_check_next_level()  # In case of multiple levels in one
	else:
		return


func add_to_score_clear_rows(simultaneously_cleared_rows: int, modifiers: Array) -> void:
	var score_expression = Expression.new()
	var score_expression_string: String = str(BASE_SCORE)
	for modifier in modifiers:
		var modifier_operation: String = modifier["modifier_operation"]
		var modifier_value: float = modifier["modifier_value"]
		score_expression_string += modifier_operation + str(modifier_value)
	
	score_expression.parse(score_expression_string)
	var base_score: float = score_expression.execute()
	
	var total_score = pow(base_score, 1.0 + ((simultaneously_cleared_rows - 1) * EXPONENT_FACTOR))
	add_to_score(int(total_score))


func get_highest_score() -> int:
	return best_score


func get_highest_level() -> int:
	return highest_level


func _update_best_scores() -> void:
	if current_level > highest_level:
		highest_level = current_level
		score_tracker.set_best_level(highest_level)
	if current_score > best_score:
		best_score = current_score
		score_tracker.set_best_score(best_score)
	save_score()
