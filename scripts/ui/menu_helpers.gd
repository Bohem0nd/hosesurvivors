class_name MenuHelpers
## Small shared builders for menu screens.


static func button(text: String, on_pressed: Callable, min_width: float = 150.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 20)
	b.pressed.connect(func() -> void:
		AudioManager.play(&"ui_select")
		on_pressed.call())
	b.focus_entered.connect(func() -> void: AudioManager.play(&"ui_move", -8.0, 0.0))
	b.mouse_entered.connect(b.grab_focus)
	return b


static func dim(alpha: float = 0.75) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.02, 0.02, 0.06, alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


static func centered_label(text: String, y: float, size: int, color: Color, title: bool = false) -> Label:
	var l := UiTheme.label(text, size, color, title)
	l.position = Vector2(0, y)
	l.size = Vector2(640, size + 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
