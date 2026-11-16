class_name MenuBackdrop
extends Control
## Slowly scrolling wasteland behind the menus.

const GROUND := preload("res://assets/sprites/environment/wasteland_ground.png")
const VIGNETTE := preload("res://assets/sprites/effects/vignette.png")
var _scroll: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_scroll = fmod(_scroll + delta * 10.0, 128.0)
	queue_redraw()


func _draw() -> void:
	var off := floorf(_scroll)
	for y in range(-1, 4):
		for x in range(-1, 6):
			draw_texture(GROUND, Vector2(x * 128.0 + off, y * 128.0 + off * 0.5), Color(0.62, 0.58, 0.66))
	draw_texture(VIGNETTE, Vector2.ZERO)
	draw_texture(VIGNETTE, Vector2.ZERO)
