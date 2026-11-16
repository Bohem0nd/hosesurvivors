class_name TelegraphZone
extends Node2D
## A readable "danger circle": fills up over `delay`, then damages the player if inside.

var radius: float = 24.0
var delay: float = 1.0
var damage: float = 15.0
var color: Color = Color(1.0, 0.35, 0.15)
var _ctx: GameContext
var _t: float = 0.0

const SQUASH := 0.7


func setup(ctx: GameContext, pos: Vector2, p_radius: float, p_delay: float, p_damage: float) -> void:
	_ctx = ctx
	position = pos
	radius = p_radius
	delay = p_delay
	damage = p_damage


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= delay:
		_detonate()


func _detonate() -> void:
	var player := _ctx.player
	var offset := player.position - position
	offset.y /= SQUASH  # match the squashed ellipse that is drawn
	if player.alive and offset.length() <= radius + player.radius * 0.5:
		player.take_damage(damage)
	_ctx.particles.burst(position, 14, Color(0.9, 0.6, 0.3), 30.0, 110.0, 0.45, 2.0)
	_ctx.rings.ring(position, radius * 0.6, radius * 1.4, 0.3, Color(1.0, 0.8, 0.5), 2.0)
	_ctx.camera.shake(2.0)
	AudioManager.play(&"boss_attack", -6.0)
	queue_free()


func _draw() -> void:
	var t := clampf(_t / delay, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SQUASH))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_circle(Vector2.ZERO, radius * t, Color(color, 0.28 + 0.2 * t))
	var blink := 1.0 if t < 0.7 or int(_t * 20.0) % 2 == 0 else 0.4
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(color, blink), 1.0)
