extends PanelContainer

@onready var qwerty: Button = $keyboard_containers/qwerty
@onready var azerty: Button = $keyboard_containers/azerty
@onready var dvorak: Button = $keyboard_containers/dvorak


func _ready() -> void:
	qwerty.connect("pressed", _on_qwerty_pressed)
	azerty.connect("pressed", _on_azerty_pressed)
	dvorak.connect("pressed", _on_dvorak_pressed)


func _on_qwerty_pressed() -> void:
	KeyboardManager.set_keyboard(KeyboardManager.ID.QWERTY)
	hide()


func _on_azerty_pressed() -> void:
	KeyboardManager.set_keyboard(KeyboardManager.ID.AZERTY)
	hide()


func _on_dvorak_pressed() -> void:
	KeyboardManager.set_keyboard(KeyboardManager.ID.DVORAK)
	hide()
