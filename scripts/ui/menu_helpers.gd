class_name MenuHelpers
## Small shared builders for menu screens.

const TOUCH_BUTTON_HEIGHT := 30.0


static func button(text: String, on_pressed: Callable, min_width: float = 150.0) -> Button:
	var b := Button.new()
	b.text = text
	# Taller on touch screens so buttons make comfortable finger targets.
	b.custom_minimum_size = Vector2(min_width, TOUCH_BUTTON_HEIGHT if Device.touch_mode else 20.0)
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


## A 640x360 design-space box kept centred on screen. Menus lay out their content
## inside it with fixed coordinates; the viewport around it may be larger.
static func frame() -> Control:
	var f := Control.new()
	f.set_anchors_preset(Control.PRESET_CENTER)
	f.offset_left = -320.0
	f.offset_top = -180.0
	f.offset_right = 320.0
	f.offset_bottom = 180.0
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f
