class_name ParticleField
extends Node2D
## Cheap pooled pixel particles drawn in one node (splashes, dust, sparks).

const MAX_PARTICLES := 700

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _size := PackedFloat32Array()
var _color := PackedColorArray()
var _count: int = 0
var drag: float = 3.5


func _ready() -> void:
	_pos.resize(MAX_PARTICLES)
	_vel.resize(MAX_PARTICLES)
	_life.resize(MAX_PARTICLES)
	_max_life.resize(MAX_PARTICLES)
	_size.resize(MAX_PARTICLES)
	_color.resize(MAX_PARTICLES)


func emit(pos: Vector2, vel: Vector2, life: float, color: Color, size: float = 1.0) -> void:
	if _count >= MAX_PARTICLES:
		return
	var i := _count
	_pos[i] = pos
	_vel[i] = vel
	_life[i] = life
	_max_life[i] = life
	_size[i] = size
	_color[i] = color
	_count += 1


func burst(pos: Vector2, count: int, color: Color, speed_min: float, speed_max: float,
		life: float = 0.35, size: float = 1.0, direction: Vector2 = Vector2.ZERO, spread: float = TAU) -> void:
	var base := direction.angle() if direction != Vector2.ZERO else 0.0
	for i in count:
		var ang := base + randf_range(-spread, spread) * 0.5
		var c := color.lightened(randf_range(0.0, 0.35))
		emit(pos, Vector2.from_angle(ang) * randf_range(speed_min, speed_max),
				life * randf_range(0.6, 1.2), c, size)


func active_count() -> int:
	return _count


func _process(delta: float) -> void:
	if _count == 0:
		return
	var damp := maxf(0.0, 1.0 - drag * delta)
	var i := 0
	while i < _count:
		_life[i] -= delta
		if _life[i] <= 0.0:
			_count -= 1
			_pos[i] = _pos[_count]
			_vel[i] = _vel[_count]
			_life[i] = _life[_count]
			_max_life[i] = _max_life[_count]
			_size[i] = _size[_count]
			_color[i] = _color[_count]
			continue
		_pos[i] += _vel[i] * delta
		_vel[i] *= damp
		i += 1
	queue_redraw()


func _draw() -> void:
	for i in _count:
		var s := _size[i]
		var c := _color[i]
		var t := _life[i] / _max_life[i]
		if t < 0.4:
			c.a *= t / 0.4
		draw_rect(Rect2(_pos[i].floor() - Vector2(s, s) * 0.5, Vector2(s, s)), c)
