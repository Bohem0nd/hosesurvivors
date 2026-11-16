class_name DamageNumbers
extends Node2D
## Floating combat text, drawn in a single node.

const MAX_NUMBERS := 70
const LIFE := 0.6

var _pos := PackedVector2Array()
var _text := PackedStringArray()
var _age := PackedFloat32Array()
var _color := PackedColorArray()
var _font: Font


func _ready() -> void:
	_font = UiTheme.font_body


func show_number(pos: Vector2, amount: float, color: Color = Color.WHITE) -> void:
	show_text(pos, str(maxi(1, roundi(amount))), color)


func show_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if _pos.size() >= MAX_NUMBERS:
		_pos.remove_at(0)
		_text.remove_at(0)
		_age.remove_at(0)
		_color.remove_at(0)
	_pos.append(pos + Vector2(randf_range(-4.0, 4.0), -6.0))
	_text.append(text)
	_age.append(0.0)
	_color.append(color)


func _process(delta: float) -> void:
	if _pos.is_empty():
		return
	var i := _pos.size() - 1
	while i >= 0:
		_age[i] += delta
		if _age[i] >= LIFE:
			_pos.remove_at(i)
			_text.remove_at(i)
			_age[i] = 0.0
			_age.remove_at(i)
			_color.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for i in _pos.size():
		var t := _age[i] / LIFE
		# Pop up fast, then hang and fade.
		var rise := 14.0 * (1.0 - (1.0 - t) * (1.0 - t))
		var p := (_pos[i] + Vector2(-float(_text[i].length()) * 3.0, -rise)).floor()
		var c := _color[i]
		var a := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
		draw_string(_font, p + Vector2(1, 1), _text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.04, 0.03, 0.06, a))
		c.a = a
		draw_string(_font, p, _text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c)
