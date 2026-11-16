class_name Enemy
extends Sprite2D
## Pooled enemy instance. Deliberately "dumb": all per-frame logic runs in
## EnemyManager's single loop, and movement comes from data.behavior.

const FLASH_SHADER := preload("res://assets/shaders/flash.gdshader")
static var _flash_material: ShaderMaterial

var data: EnemyData
var uid: int = 0
var index: int = -1          # slot in EnemyManager.active (for O(1) removal)
var alive: bool = false
var hp: float = 0.0
var max_hp: float = 0.0
var speed: float = 0.0
var damage: float = 0.0
var radius: float = 6.0
var knock: Vector2 = Vector2.ZERO
var attack_cd: float = 0.0
var flash_t: float = 0.0
var anim_t: float = 0.0
var shield: float = 0.0
var shield_max: float = 0.0
var shield_t: float = 0.0
var dmg_accum: float = 0.0
var dmg_accum_t: float = 0.0
## Scratch space for the behavior resource (behaviors are shared, state is not).
var state: Dictionary = {}

var _shadow: Sprite2D


func _init() -> void:
	if _flash_material == null:
		_flash_material = ShaderMaterial.new()
		_flash_material.shader = FLASH_SHADER
	_shadow = Sprite2D.new()
	_shadow.texture = preload("res://assets/sprites/effects/shadow.png")
	_shadow.show_behind_parent = true
	add_child(_shadow)


func activate(p_data: EnemyData, pos: Vector2, hp_mult: float, dmg_mult: float) -> void:
	data = p_data
	texture = data.texture
	hframes = maxi(1, data.hframes)
	frame = 0
	scale = Vector2.ONE * data.sprite_scale
	position = pos
	max_hp = data.max_health * hp_mult
	hp = max_hp
	speed = data.speed
	damage = data.damage * dmg_mult
	radius = data.radius
	knock = Vector2.ZERO
	attack_cd = 0.0
	flash_t = 0.0
	anim_t = randf()
	shield_max = data.shield
	shield = shield_max
	shield_t = 0.0
	dmg_accum = 0.0
	dmg_accum_t = 0.0
	state.clear()
	material = null
	modulate = Color.WHITE
	alive = true
	var h := float(texture.get_height())
	_shadow.position = Vector2(0.0, h * 0.5 + (4.0 if data.flying else -1.0))
	_shadow.scale = Vector2.ONE * (float(texture.get_width()) / hframes) / 16.0
	queue_redraw()


func set_flash(on: bool) -> void:
	material = _flash_material if on else null


func _draw() -> void:
	if data == null:
		return
	if shield > 0.0:
		var a := 0.35 + 0.5 * (shield / shield_max)
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 20, Color(0.5, 0.8, 1.0, a), 1.0)
	if data.tier == EnemyData.Tier.ELITE:
		var w := 20.0
		var y := -float(texture.get_height()) * 0.5 - 5.0
		draw_rect(Rect2(-w * 0.5 - 1.0, y - 1.0, w + 2.0, 4.0), Color(0.04, 0.03, 0.06))
		draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 2.0), Color(0.9, 0.3, 0.25))
