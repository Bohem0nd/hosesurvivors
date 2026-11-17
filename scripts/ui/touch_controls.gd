class_name TouchControls
extends CanvasLayer
## Floating virtual joystick: put a finger down anywhere, drag to move. The stick
## base follows the finger if it drags past the rim, so direction changes stay quick.
## Feeds the regular move_* actions, so Player never needs to know about touch.

const RADIUS := 34.0
const KNOB_RADIUS := 12.0
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _finger: int = -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _canvas: Control
var _hint: Label


func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_stick)
	add_child(_canvas)

	_hint = UiTheme.label("DRAG ANYWHERE TO MOVE", 8, UiTheme.WATER_LIGHT, true)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -160.0
	_hint.offset_right = 160.0
	_hint.offset_top = -70.0
	_hint.offset_bottom = -58.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.visible = Device.touch_mode
	_canvas.add_child(_hint)


func _exit_tree() -> void:
	_release()


func _process(_delta: float) -> void:
	# Touches that end while a modal pauses the game never reach us; drop the stick.
	if get_tree().paused and _finger != -1:
		_release()
	if _hint.visible:
		_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.005)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _finger == -1:
			_finger = touch.index
			_origin = touch.position
			_knob = touch.position
			_hint.visible = false
			_canvas.queue_redraw()
		elif not touch.pressed and touch.index == _finger:
			_release()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _finger:
		var pos := (event as InputEventScreenDrag).position
		var offset := pos - _origin
		if offset.length() > RADIUS:
			_origin = pos - offset.normalized() * RADIUS
		_knob = pos
		_apply((_knob - _origin) / RADIUS)
		_canvas.queue_redraw()


func _apply(v: Vector2) -> void:
	_set_strength(ACTIONS[0], maxf(-v.x, 0.0))
	_set_strength(ACTIONS[1], maxf(v.x, 0.0))
	_set_strength(ACTIONS[2], maxf(-v.y, 0.0))
	_set_strength(ACTIONS[3], maxf(v.y, 0.0))


func _set_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, minf(strength, 1.0))
	elif Input.is_action_pressed(action):
		Input.action_release(action)


func _release() -> void:
	if _finger == -1:
		return
	_finger = -1
	_apply(Vector2.ZERO)
	if _canvas != null:
		_canvas.queue_redraw()


func _draw_stick() -> void:
	if _finger == -1:
		return
	var o := _origin.round()
	_canvas.draw_circle(o, RADIUS, Color(UiTheme.INK, 0.35))
	_canvas.draw_arc(o, RADIUS, 0.0, TAU, 32, Color(UiTheme.WATER_LIGHT, 0.55), 1.0)
	var k := o + (_knob - _origin).limit_length(RADIUS).round()
	_canvas.draw_circle(k, KNOB_RADIUS, Color(UiTheme.WATER, 0.7))
	_canvas.draw_arc(k, KNOB_RADIUS, 0.0, TAU, 20, Color(UiTheme.WATER_LIGHT, 0.9), 1.0)
