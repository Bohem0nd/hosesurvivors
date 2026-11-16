extends Node
## Registers gameplay input actions at startup (keyboard + gamepad) so bindings
## live in one readable place. Menu navigation uses Godot's built-in ui_* actions.

const DEADZONE := 0.25


func _ready() -> void:
	_add("move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT)
	_add("move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT)
	_add("move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP)
	_add("move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN)
	_add("pause", [KEY_ESCAPE, KEY_P], -1, 0.0, JOY_BUTTON_START)


func _add(action: StringName, keys: Array, axis: int, axis_value: float, button: int) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE)
	for key: Key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis as JoyAxis
		motion.axis_value = axis_value
		InputMap.action_add_event(action, motion)
	if button >= 0:
		var btn := InputEventJoypadButton.new()
		btn.button_index = button as JoyButton
		InputMap.action_add_event(action, btn)
