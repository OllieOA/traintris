extends Node
signal score_updated  # Trigger the UI to update

var current_score: int = 0
@export var best_score: int = 0

const EXPONENT_FACTOR: float = 0.1
const BASE_SCORE: int = 10
const BASE_PONTS_PER_LEVEL: int = 100

const RATIO_POINTS_FOR_LEVEL: Dictionary = {
	0: 0,
	1: 1,
	2: 2,
	3: 4,
	5: 6,
	6: 10,
	7: 15,
	8: 20,
	9: 30,
}


func _ready() -> void:
	SignalBus.connect("rows_cleared", add_to_score_clear_rows)
	# TODO: Load score
	pass


func _add_to_score(val: int) -> void:
	current_score += val
	emit_signal("score_updated")


func save_score() -> void:
	pass


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
	_add_to_score(int(total_score))
	print("NEW SCORE " + str(int(total_score)))

	
