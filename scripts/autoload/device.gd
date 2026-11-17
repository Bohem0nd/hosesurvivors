extends Node
## Adapts the game to the screen it runs on: phones, tablets, odd browser windows.
##
## - Fits the viewport to the window so there are no black bars: the 640x360 design
##   area is always visible and the extra space shows more of the world (up to
##   MAX_VIEW). Desktop keeps integer pixel scaling; touch screens scale fractionally
##   so the game fills the whole display.
## - Tracks whether the player is using touch (`touch_mode`), so screens can show
##   touch controls, bigger buttons and touch hints.
## - Shows a "rotate your device" prompt on touch screens held in portrait.

signal touch_mode_changed(enabled: bool)
## Emitted when a touch device is turned to portrait (the game should pause).
signal orientation_blocked

const BASE := Vector2(640.0, 360.0)
const MAX_VIEW := Vector2(864.0, 480.0)

var touch_mode: bool = false
var portrait: bool = false

var _overlay: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_mode = DisplayServer.is_touchscreen_available() and (OS.has_feature("mobile")
			or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("web_macos"))
	_build_overlay()
	get_window().size_changed.connect(_fit)
	_fit()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_touch_mode(true)
	elif (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		_set_touch_mode(false)


## Size of the visible game area in canvas pixels (at least BASE, at most MAX_VIEW).
func view_size() -> Vector2:
	return get_tree().root.get_visible_rect().size


func _set_touch_mode(enabled: bool) -> void:
	if enabled == touch_mode:
		return
	touch_mode = enabled
	_fit()
	touch_mode_changed.emit(enabled)


func _fit() -> void:
	var root := get_tree().root
	var win := Vector2(get_window().size)
	if win.x <= 0.0 or win.y <= 0.0:
		return
	var fit := minf(win.x / BASE.x, win.y / BASE.y)
	var pixel_perfect := not touch_mode and fit >= 1.0
	var scale := floorf(fit) if pixel_perfect else fit
	var view := (win / scale).floor().clamp(BASE, MAX_VIEW)
	root.content_scale_size = Vector2i(view)
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if pixel_perfect \
			else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

	var was_portrait := portrait
	portrait = touch_mode and win.y > win.x
	_overlay.visible = portrait
	if portrait and not was_portrait:
		orientation_blocked.emit()


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 99
	_overlay.visible = false
	add_child(_overlay)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme
	_overlay.add_child(root)  # mouse_filter STOP: swallows taps while shown
	var bg := ColorRect.new()
	bg.color = UiTheme.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	for line: Array in [["ROTATE YOUR", 24, UiTheme.BRASS, true], ["DEVICE", 24, UiTheme.BRASS, true],
			["Jon Hose only fights in landscape.", 16, UiTheme.TEXT, false]]:
		var l := UiTheme.label(line[0], line[1], line[2], line[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
