class_name ProjectileManager
extends Node2D
## Pools and simulates every projectile (player and enemy) in one loop.
## Player projectiles hit enemies via the spatial grid; enemy projectiles only
## test against the player.

enum Team { PLAYER, ENEMY }

const MAX_ACTIVE := 900

var ctx: GameContext
var active: Array[Projectile] = []
var _pool: ObjectPool
var _query: Array[Enemy] = []


func setup(p_ctx: GameContext, prewarm: int = 150) -> void:
	ctx = p_ctx
	_pool = ObjectPool.new(self, func() -> Node: return Projectile.new(), prewarm)


func spawn(config: ProjectileConfig, pos: Vector2, dir: Vector2, damage: float, knockback: float,
		pierce: int, size: float, lifetime: float, team: Team = Team.PLAYER) -> Projectile:
	if active.size() >= MAX_ACTIVE:
		return null
	var p: Projectile = _pool.acquire()
	p.config = config
	p.texture = config.texture
	p.position = pos
	p.velocity = dir * config.speed
	p.rotation = dir.angle() if config.rotate_to_velocity else 0.0
	p.scale = Vector2.ONE * size
	p.damage = damage
	p.knockback = knockback
	p.pierce_left = pierce
	p.life = lifetime
	p.radius = config.radius * size
	p.team = team
	p.hit_uids.clear()
	p.index = active.size()
	active.append(p)
	return p


func _release(p: Projectile) -> void:
	var last: Projectile = active[active.size() - 1]
	active[p.index] = last
	last.index = p.index
	active.pop_back()
	p.index = -1
	_pool.release(p)


func clear_team(team: Team) -> void:
	for i in range(active.size() - 1, -1, -1):
		if active[i].team == team:
			_release(active[i])


func _process(delta: float) -> void:
	if ctx == null:
		return
	var player := ctx.player
	var i := active.size() - 1
	while i >= 0:
		if i >= active.size():
			# Something released projectiles while we were iterating (e.g. clear_team).
			i = active.size() - 1
			continue
		var p := active[i]
		i -= 1
		p.position += p.velocity * delta
		if p.config.spin != 0.0:
			p.rotation += p.config.spin * delta
		p.life -= delta
		var dead := p.life <= 0.0
		if dead:
			_expire_effect(p)
		elif p.team == Team.PLAYER:
			dead = _hit_enemies(p)
		elif player.alive and p.position.distance_squared_to(player.position) < pow(p.radius + player.radius, 2.0):
			player.take_damage(p.damage)
			ctx.particles.burst(p.position, 4, p.config.hit_color, 20.0, 60.0, 0.3, 2.0)
			dead = true
		if dead:
			_release(p)


func _hit_enemies(p: Projectile) -> bool:
	_query.clear()
	ctx.enemies.grid.query_circle(p.position, p.radius, _query)
	for enemy in _query:
		if not enemy.alive or p.hit_uids.has(enemy.uid):
			continue
		p.hit_uids.append(enemy.uid)
		var dir := p.velocity.normalized()
		var hit_pos := enemy.position - dir * enemy.radius * 0.6
		ctx.particles.burst(hit_pos, p.config.hit_particles, p.config.hit_color, 25.0, 90.0, 0.3, 1.0, -dir, PI * 1.2)
		AudioManager.play(p.config.hit_sfx, -10.0, 0.25)
		ctx.enemies.damage(enemy, p.damage, dir * p.knockback)
		p.pierce_left -= 1
		if p.pierce_left < 0:
			return true
	return false


func _expire_effect(p: Projectile) -> void:
	if p.config.leaves_puddle and p.team == Team.PLAYER:
		ctx.rings.puddle(p.position, 5.0 * p.scale.x, 1.4, Color(0.2, 0.42, 0.75, 0.45))
		ctx.particles.burst(p.position, 2, p.config.hit_color, 10.0, 40.0, 0.25, 1.0)
