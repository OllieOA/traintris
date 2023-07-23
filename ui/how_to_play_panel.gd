extends PanelContainer


func _input(event: InputEvent) -> void:
	if visible:
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_released():
				hide()
