class_name GreatDryingBehavior
extends EnemyBehavior
## Boss: The Great Drying. Slowly advances and cycles three telegraphed attacks:
##   1. Drought Zones  - danger circles on and around the player.
##   2. Dust Nova      - wind-up flash, then a radial ring of dust orbs.
##   3. Summon         - a ring of minions.
## Below `enrage_threshold` health it attacks faster and harder.

const TelegraphScript := preload("res://scripts/effects/telegraph_zone.gd")

@export var attack_interval: float = 3.4
@export var enrage_threshold: float = 0.5
@export var zone_count: int = 4
@export var zone_radius: float = 30.0
@export var zone_delay: float = 1.0
@export var zone_damage: float = 22.0
@export var nova_count: int = 16
@export var nova_windup: float = 0.7
@export var nova_damage: float = 14.0
@export var nova_projectile: ProjectileConfig
@export var summon: EnemyData
@export var summon_count: int = 8


func start(enemy: Enemy, _ctx: GameContext) -> void:
	enemy.state[&"timer"] = 2.0
	enemy.state[&"pattern"] = 0
	enemy.state[&"windup"] = 0.0
	enemy.state[&"novas"] = 0


func update(enemy: Enemy, ctx: GameContext, dir: Vector2, _dist: float, delta: float) -> Vector2:
	var enraged := enemy.hp < enemy.max_hp * enrage_threshold
	var windup: float = enemy.state[&"windup"]
	if windup > 0.0:
		# Winding up a nova: stand still and strobe so the player can read it.
		windup -= delta
		enemy.state[&"windup"] = windup
		enemy.set_flash(int(windup * 16.0) % 2 == 0)
		if windup <= 0.0:
			enemy.set_flash(false)
			_fire_nova(enemy, ctx, enraged)
			var left: int = enemy.state[&"novas"] - 1
			enemy.state[&"novas"] = left
			if left > 0:
				enemy.state[&"windup"] = 0.35
		return Vector2.ZERO

	var timer: float = enemy.state[&"timer"] - delta
	if timer <= 0.0:
		timer = attack_interval * (0.65 if enraged else 1.0)
		var pattern: int = enemy.state[&"pattern"]
		enemy.state[&"pattern"] = (pattern + 1) % 3
		match pattern:
			0:
				_drought_zones(enemy, ctx, enraged)
			1:
				enemy.state[&"windup"] = nova_windup
				enemy.state[&"novas"] = 2 if enraged else 1
				AudioManager.play(&"telegraph")
			2:
				_summon(enemy, ctx)
	enemy.state[&"timer"] = timer
	return dir * enemy.speed * (1.35 if enraged else 1.0)


func _drought_zones(_enemy: Enemy, ctx: GameContext, enraged: bool) -> void:
	AudioManager.play(&"telegraph")
	var count := zone_count + (2 if enraged else 0)
	for i in count:
		var zone: TelegraphZone = TelegraphScript.new()
		# First zone lands on the player (leading their movement); the rest scatter.
		var pos := ctx.player.position + ctx.player.velocity * 0.5
		if i > 0:
			pos = ctx.player.position + Vector2.from_angle(randf() * TAU) * randf_range(35.0, 110.0)
		zone.setup(ctx, pos, zone_radius, zone_delay + 0.08 * i, zone_damage)
		ctx.hazards.add_child(zone)


func _fire_nova(enemy: Enemy, ctx: GameContext, enraged: bool) -> void:
	AudioManager.play(&"boss_attack")
	ctx.camera.shake(3.0)
	ctx.rings.ring(enemy.position, 10.0, 60.0, 0.35, Color(1.0, 0.7, 0.4), 2.0)
	var count := nova_count + (4 if enraged else 0)
	var offset := randf() * TAU
	for i in count:
		var ang := offset + TAU * float(i) / float(count)
		ctx.projectiles.spawn(nova_projectile, enemy.position, Vector2.from_angle(ang), nova_damage,
				0.0, 0, 1.0, nova_projectile.lifetime, ProjectileManager.Team.ENEMY)


func _summon(enemy: Enemy, ctx: GameContext) -> void:
	if summon == null:
		return
	ctx.rings.ring(enemy.position, 20.0, 70.0, 0.4, Color(0.8, 0.6, 0.4), 1.0)
	for i in summon_count:
		var ang := TAU * float(i) / float(summon_count)
		var pos := enemy.position + Vector2.from_angle(ang) * 48.0
		ctx.particles.burst(pos, 5, Color(0.8, 0.65, 0.45), 10.0, 40.0, 0.4, 2.0)
		ctx.enemies.spawn(summon, pos)
