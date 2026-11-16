class_name Player
extends Node2D
## The playable character. Fully driven by CharacterData: stats, sprite, starting
## weapon and passive all come from the resource.

const SHADOW_TEX := preload("res://assets/sprites/effects/shadow.png")
const IFRAME_TIME := 0.25
const ANIM_FPS := 8.0

var data: CharacterData
var ctx: GameContext
var stats := StatBlock.new()
var health: HealthComponent
var weapons: WeaponController
var passive: PassiveAbility
var radius: float = 5.0
var alive: bool = true
var velocity: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT
## When set (tests / demos), replaces device input. Callable returning Vector2.
var input_override: Callable
var invulnerable: bool = false

var _body: Sprite2D
var _iframes: float = 0.0
var _anim_t: float = 0.0
var _regen_accum: float = 0.0


func setup(p_data: CharacterData, p_ctx: GameContext) -> void:
	data = p_data
	ctx = p_ctx
	stats.set_base(Stats.MAX_HEALTH, data.max_health)
	stats.set_base(Stats.MOVE_SPEED, data.move_speed)
	stats.set_base(Stats.DAMAGE, data.damage_multiplier)

	var shadow := Sprite2D.new()
	shadow.texture = SHADOW_TEX
	add_child(shadow)
	_body = Sprite2D.new()
	_body.texture = data.sprite_sheet
	_body.hframes = data.frame_count
	add_child(_body)
	shadow.position.y = data.sprite_sheet.get_height() * 0.5 - 1.0

	health = HealthComponent.new()
	add_child(health)
	health.setup(stats.get_stat(Stats.MAX_HEALTH))
	health.died.connect(_on_died)
	stats.changed.connect(_on_stat_changed)

	weapons = WeaponController.new()
	add_child(weapons)
	weapons.setup(self, ctx)
	if data.starting_weapon != null:
		weapons.add_weapon(data.starting_weapon)

	if data.passive_script != null:
		passive = data.passive_script.new()
		add_child(passive)
		passive.setup(self, ctx, data.passive_params)


func _process(delta: float) -> void:
	if not alive:
		return
	var input: Vector2 = input_override.call() if input_override.is_valid() \
			else Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length_squared() > 1.0:
		input = input.normalized()
	velocity = input * stats.get_stat(Stats.MOVE_SPEED)
	position += velocity * delta

	var moving := input.length_squared() > 0.01
	if moving:
		facing = input.normalized()
		if absf(input.x) > 0.1:
			_body.flip_h = input.x < 0.0
	_anim_t += delta * (ANIM_FPS if moving else ANIM_FPS * 0.3)
	var frames := data.walk_frames if moving else data.idle_frames
	_body.frame = frames.x + int(_anim_t) % (frames.y - frames.x + 1)

	if _iframes > 0.0:
		_iframes -= delta
		_body.modulate = Color(1.0, 0.45, 0.45) if _iframes > 0.0 else Color.WHITE

	var regen := stats.get_stat(Stats.REGEN)
	if regen > 0.0 and health.health < health.max_health:
		_regen_accum += regen * delta
		if _regen_accum >= 1.0:
			health.heal(floorf(_regen_accum))
			_regen_accum -= floorf(_regen_accum)


func take_damage(amount: float) -> void:
	if not alive or invulnerable or _iframes > 0.0:
		return
	var final := amount * (1.0 - clampf(stats.get_stat(Stats.ARMOR), 0.0, 0.8))
	_iframes = IFRAME_TIME
	ctx.camera.shake(3.0)
	ctx.particles.burst(position, 6, Color(0.9, 0.2, 0.2), 30.0, 90.0, 0.35, 2.0)
	AudioManager.play(&"player_hurt")
	health.damage(final)
	Events.player_damaged.emit(final)


func heal(amount: float) -> void:
	var healed := health.heal(amount)
	if healed > 0.0:
		ctx.numbers.show_text(position + Vector2(0, -14), "+%d" % roundi(healed), UiTheme.GOOD)
		Events.player_healed.emit(healed)


func _on_stat_changed(stat: StringName) -> void:
	if stat == Stats.MAX_HEALTH and health != null:
		health.set_max(stats.get_stat(Stats.MAX_HEALTH))


func _on_died() -> void:
	alive = false
	velocity = Vector2.ZERO
	_body.modulate = Color(0.5, 0.4, 0.4)
	_body.rotation = PI * 0.5
	weapons.set_active(false)
	ctx.particles.burst(position, 30, Color(0.85, 0.2, 0.2), 30.0, 160.0, 0.7, 2.0)
	ctx.camera.shake(8.0)
	Events.player_died.emit()
