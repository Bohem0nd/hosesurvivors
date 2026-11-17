class_name EnemyManager
extends Node2D
## Owns every enemy: pooling, the per-frame update loop, the spatial grid,
## damage resolution and death rewards. One loop here replaces hundreds of
## per-node _process calls.

const CONTACT_COOLDOWN := 0.8
const DESPAWN_DISTANCE := 620.0
const RESPAWN_DISTANCE := 400.0
const NUMBER_FLUSH_TIME := 0.18

var ctx: GameContext
var active: Array[Enemy] = []
var grid := SpatialGrid.new(32.0)
## Difficulty multipliers, set by the SpawnDirector as the run progresses.
var health_scale: float = 1.0
var damage_scale: float = 1.0

var _pool: ObjectPool
var _next_uid: int = 1
var _query: Array[Enemy] = []


func setup(p_ctx: GameContext, prewarm: int = 200) -> void:
	ctx = p_ctx
	y_sort_enabled = true
	_pool = ObjectPool.new(self, func() -> Node: return Enemy.new(), prewarm)


func spawn(data: EnemyData, pos: Vector2) -> Enemy:
	var enemy: Enemy = _pool.acquire()
	enemy.uid = _next_uid
	_next_uid += 1
	var hp_mult := health_scale if data.tier != EnemyData.Tier.BOSS else 1.0
	enemy.activate(data, pos, hp_mult, damage_scale)
	enemy.index = active.size()
	active.append(enemy)
	if data.behavior != null:
		data.behavior.start(enemy, ctx)
	if data.tier == EnemyData.Tier.BOSS:
		Events.boss_spawned.emit(enemy)
	return enemy


func count() -> int:
	return active.size()


func nearest(pos: Vector2, max_distance: float) -> Enemy:
	return grid.nearest(pos, max_distance)


## Applies damage (shield first). Returns true if the enemy died.
func damage(enemy: Enemy, amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if not enemy.alive:
		return false
	if enemy.shield > 0.0:
		enemy.shield_t = enemy.data.shield_regen_delay
		enemy.shield -= amount
		enemy.queue_redraw()
		if enemy.shield > 0.0:
			return false
		amount = -enemy.shield
		enemy.shield = 0.0
		ctx.rings.ring(enemy.position, enemy.radius, enemy.radius + 14.0, 0.25, Color(0.6, 0.85, 1.0), 2.0)
	elif enemy.shield_max > 0.0:
		enemy.shield_t = enemy.data.shield_regen_delay
	enemy.hp -= amount
	enemy.knock += knockback * (1.0 - enemy.data.knockback_resist)
	enemy.flash_t = 0.07
	enemy.set_flash(true)
	enemy.dmg_accum += amount
	if enemy.dmg_accum_t <= 0.0:
		enemy.dmg_accum_t = NUMBER_FLUSH_TIME
	if enemy.data.tier == EnemyData.Tier.ELITE:
		enemy.queue_redraw()
	if enemy.hp <= 0.0:
		_kill(enemy)
		return true
	return false


func _flush_number(enemy: Enemy) -> void:
	if enemy.dmg_accum >= 0.5:
		var big := enemy.dmg_accum >= 40.0
		ctx.numbers.show_number(enemy.position + Vector2(0.0, -enemy.radius),
				enemy.dmg_accum, Color(1.0, 0.85, 0.3) if big else Color.WHITE)
	enemy.dmg_accum = 0.0


func _kill(enemy: Enemy) -> void:
	var data := enemy.data
	var pos := enemy.position
	_flush_number(enemy)
	var big := data.tier != EnemyData.Tier.NORMAL
	ctx.particles.burst(pos, 22 if big else 7, data.death_color, 20.0, 120.0 if big else 80.0, 0.45, 2.0)
	ctx.rings.ring(pos, enemy.radius * 0.5, enemy.radius * (3.0 if big else 1.8), 0.25, Color(1, 1, 1, 0.8))
	if big:
		ctx.camera.shake(6.0 if data.tier == EnemyData.Tier.BOSS else 3.5)
	AudioManager.play(&"enemy_death", -6.0, 0.2)
	ctx.pickups.drop_rewards(data, pos)
	RunState.register_kill()
	_release(enemy)
	Events.enemy_killed.emit(data, pos)
	if data.tier == EnemyData.Tier.BOSS:
		Events.boss_defeated.emit(data)


func _release(enemy: Enemy) -> void:
	enemy.alive = false
	var last: Enemy = active[active.size() - 1]
	active[enemy.index] = last
	last.index = enemy.index
	active.pop_back()
	enemy.index = -1
	enemy.set_flash(false)
	_pool.release(enemy)


## Removes every non-boss enemy without rewards (used when the boss arrives).
func clear_normals() -> void:
	for i in range(active.size() - 1, -1, -1):
		var enemy := active[i]
		if enemy.data.tier == EnemyData.Tier.NORMAL:
			ctx.particles.burst(enemy.position, 4, enemy.data.death_color, 10.0, 50.0, 0.4, 2.0)
			_release(enemy)


func _process(delta: float) -> void:
	if ctx == null:
		return
	var player := ctx.player
	var player_pos := player.position
	var player_radius := player.radius
	# Keep the wrap-around ring just off-screen, however much of the world is visible.
	var respawn_distance := maxf(RESPAWN_DISTANCE, Device.view_size().length() * 0.5 + 24.0)
	var despawn_distance := maxf(DESPAWN_DISTANCE, respawn_distance + 160.0)
	var n := active.size()
	var i := 0
	while i < n:
		var enemy := active[i]
		i += 1
		var to_player := player_pos - enemy.position
		var dist := to_player.length()
		var dir := to_player / dist if dist > 0.001 else Vector2.RIGHT

		var vel := enemy.data.behavior.update(enemy, ctx, dir, dist, delta) \
				if enemy.data.behavior != null else dir * enemy.speed
		var pos := enemy.position + (vel + enemy.knock) * delta
		enemy.knock *= maxf(0.0, 1.0 - 7.0 * delta)

		# Soft separation against a few neighbours in the same cell (last frame's grid).
		var bucket := grid.bucket_at(pos)
		var checks := mini(bucket.size(), 5)
		for j in checks:
			var other := bucket[j]
			if other == enemy:
				continue
			var diff := pos - other.position
			var min_dist := enemy.radius + other.radius
			var d2 := diff.length_squared()
			if d2 < min_dist * min_dist and d2 > 0.0001:
				var d := sqrt(d2)
				pos += diff / d * (min_dist - d) * minf(1.0, 8.0 * delta)
		enemy.position = pos
		if absf(dir.x) > 0.1:
			enemy.flip_h = dir.x < 0.0

		# Timers.
		enemy.anim_t += delta * enemy.data.anim_fps
		if enemy.hframes > 1:
			enemy.frame = int(enemy.anim_t) % enemy.hframes
		if enemy.flash_t > 0.0:
			enemy.flash_t -= delta
			if enemy.flash_t <= 0.0:
				enemy.set_flash(false)
		if enemy.dmg_accum_t > 0.0:
			enemy.dmg_accum_t -= delta
			if enemy.dmg_accum_t <= 0.0:
				_flush_number(enemy)
		if enemy.shield_max > 0.0 and enemy.shield < enemy.shield_max:
			enemy.shield_t -= delta
			if enemy.shield_t <= 0.0:
				enemy.shield = enemy.shield_max
				enemy.queue_redraw()

		# Contact damage.
		if enemy.attack_cd > 0.0:
			enemy.attack_cd -= delta
		elif dist < enemy.radius + player_radius and player.alive:
			enemy.attack_cd = CONTACT_COOLDOWN
			player.take_damage(enemy.damage)

		# Left far behind? Wrap back to the spawn ring instead of wasting a slot.
		if dist > despawn_distance and enemy.data.tier != EnemyData.Tier.BOSS:
			enemy.position = player_pos + Vector2.from_angle(randf() * TAU) * respawn_distance

	grid.clear()
	for enemy in active:
		grid.insert(enemy)
