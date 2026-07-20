extends Node

func _init() -> void:
	_add_action("move_left", KEY_A, KEY_LEFT)
	_add_action("move_right", KEY_D, KEY_RIGHT)
	_add_action("jump", KEY_SPACE, KEY_UP)
	_add_action("attack", KEY_J, KEY_ENTER)
	_add_action("dodge", KEY_K, KEY_SHIFT)

func _add_action(action_name: String, keycode1: Key, keycode2: Key = KEY_NONE) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var event1 := InputEventKey.new()
	event1.physical_keycode = keycode1
	InputMap.action_add_event(action_name, event1)
	if keycode2 != KEY_NONE:
		var event2 := InputEventKey.new()
		event2.physical_keycode = keycode2
		InputMap.action_add_event(action_name, event2)
