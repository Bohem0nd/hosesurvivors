class_name RingField
extends Node2D
## Ground-level effects: expanding shockwave rings and fading puddles.

const MAX_ITEMS := 90

class Item:
	var pos: Vector2
	var r0: float
	var r1: float
	var life: float
	var max_life: float
	var color: Color
	var filled: bool
	var width: float

var _items: Array[Item] = []


func ring(pos: Vector2, r0: float, r1: float, life: float, color: Color, width: float = 1.0) -> void:
	_add(pos, r0, r1, life, color, false, width)


func puddle(pos: Vector2, radius: float, life: float, color: Color) -> void:
	_add(pos, radius * 0.5, radius, life, color, true, 1.0)


func _add(pos: Vector2, r0: float, r1: float, life: float, color: Color, filled: bool, width: float) -> void:
	if _items.size() >= MAX_ITEMS:
		_items.remove_at(0)
	var it := Item.new()
	it.pos = pos
	it.r0 = r0
	it.r1 = r1
	it.life = life
	it.max_life = life
	it.color = color
	it.filled = filled
	it.width = width
	_items.append(it)


func _process(delta: float) -> void:
	if _items.is_empty():
		return
	var i := _items.size() - 1
	while i >= 0:
		_items[i].life -= delta
		if _items[i].life <= 0.0:
			_items.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for it in _items:
		var t := 1.0 - it.life / it.max_life
		var c := it.color
		if it.filled:
			var grow := minf(1.0, t * 6.0)
			c.a *= 1.0 - t
			# Squashed circle reads as a puddle on the ground plane.
			draw_set_transform(it.pos, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, lerpf(it.r0, it.r1, grow), c)
		else:
			c.a *= 1.0 - t * t
			draw_set_transform(it.pos, 0.0, Vector2.ONE)
			draw_arc(Vector2.ZERO, lerpf(it.r0, it.r1, 1.0 - (1.0 - t) * (1.0 - t)), 0.0, TAU, 24, c, it.width)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
