class_name GameCamera
extends Camera2D
## Follows a target with trauma-based screen shake.

var target: Node2D
var _trauma: float = 0.0
var _shake_scale: float = 1.0


func _ready() -> void:
	_shake_scale = SaveManager.get_setting("screen_shake", 1.0)
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE


## `amount` is roughly the peak offset in pixels.
func shake(amount: float) -> void:
	_trauma = minf(maxf(_trauma, amount), 10.0)


func _process(delta: float) -> void:
	if target != null:
		position = target.position
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - 22.0 * delta)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _trauma * _shake_scale
	else:
		offset = Vector2.ZERO
