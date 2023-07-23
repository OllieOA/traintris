extends Node

enum ID {QWERTY, AZERTY, DVORAK}

const ACTION_MAPS: Dictionary = {
	ID.QWERTY: {
		"rotate_anticlockwise": [KEY_Q],
		"rotate_clockwise": [KEY_E],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_left": [KEY_A, KEY_LEFT],
	},
	ID.AZERTY: {
		"rotate_anticlockwise": [KEY_A],
		"rotate_clockwise": [KEY_E],
		"move_up": [KEY_Z, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_left": [KEY_Q, KEY_LEFT],
	},
	ID.DVORAK: {
		"rotate_anticlockwise": [KEY_APOSTROPHE],
		"rotate_clockwise": [KEY_PERIOD],
		"move_up": [KEY_COMMA, KEY_UP],
		"move_down": [KEY_O, KEY_DOWN],
		"move_right": [KEY_E, KEY_RIGHT],
		"move_left": [KEY_A, KEY_LEFT],
	}
}


func set_keyboard(keyboard: ID) -> void:
	for action in ACTION_MAPS[keyboard].keys():
		InputMap.action_erase_events(action)
		for key in ACTION_MAPS[keyboard][action]:
			var new_input = InputEventKey.new()
			new_input.set_physical_keycode(key)
			InputMap.action_add_event(action, new_input)
		if action == "rotate_anticlockwise":
			var new_input = InputEventMouseButton.new()
			new_input.set_button_index(MOUSE_BUTTON_RIGHT)
			InputMap.action_add_event(action, new_input)
		elif action == "rotate_clockwise":
			var new_input = InputEventMouseButton.new()
			new_input.set_button_index(MOUSE_BUTTON_LEFT)
			InputMap.action_add_event(action, new_input)
