extends Button

@export var action_name: String = ""

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	button_down.connect(func(): Input.action_press(action_name))
	button_up.connect(func(): Input.action_release(action_name))
