class_name PixelBar
extends Control
## Chunky retro progress bar with a trailing "ghost" that shows recent loss.

var fill_color: Color = UiTheme.WATER
var back_color: Color = UiTheme.INK
var border_color: Color = UiTheme.BRASS
var ghost_color: Color = Color(1, 1, 1, 0.7)
var show_ghost: bool = false
## Optional caption drawn centred inside the bar.
var text: String = "":
	set(value):
		text = value
		queue_redraw()
var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		if ratio > _ghost:
			_ghost = ratio
		queue_redraw()

var _ghost: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if show_ghost and _ghost > ratio:
		_ghost = maxf(ratio, _ghost - 0.5 * delta)
		queue_redraw()


func _draw() -> void:
	var inner := Rect2(Vector2.ONE, size - Vector2(2, 2))
	draw_rect(Rect2(Vector2.ZERO, size), border_color)
	draw_rect(inner, back_color)
	if show_ghost and _ghost > ratio:
		draw_rect(Rect2(inner.position, Vector2(floorf(inner.size.x * _ghost), inner.size.y)), ghost_color)
	var w := floorf(inner.size.x * ratio)
	if w > 0.0:
		draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill_color)
		draw_rect(Rect2(inner.position, Vector2(w, 1.0)), fill_color.lightened(0.45))
	if text != "":
		var font := UiTheme.font_body
		var w_text := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var pos := Vector2(floorf((size.x - w_text) * 0.5), floorf(size.y * 0.5) + 3.0)
		draw_string(font, pos + Vector2.ONE, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiTheme.INK)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiTheme.TEXT)
