extends TestSuite

const DRY_ONE := "res://resources/enemies/dry_one.tres"
const BUREAUCRAT := "res://resources/enemies/bureaucrat.tres"


func test_weapon_stats_follow_levels_and_player_stats() -> void:
	var game := make_game()
	var player := game.ctx.player
	var hose := player.weapons.get_weapon(&"holy_hose")
	var base_damage := hose.get_damage()
	var base_count := hose.get_projectile_count()
	var base_cd := hose.get_cooldown()
	check_near(base_damage, hose.data.damage, "level 1 damage")
	player.weapons.level_up(&"holy_hose")   # +2 damage
	check_near(hose.get_damage(), base_damage + 2.0, "level 2 damage")
	player.weapons.level_up(&"holy_hose")   # +1 jet
	check_eq(hose.get_projectile_count(), base_count + 1, "level 3 jets")
	player.stats.add_modifier(&"damage_water", StatModifier.Mode.PERCENT, 0.2)
	check_near(hose.get_damage(), (base_damage + 2.0) * 1.2, "water tag multiplier", 0.001)
	player.stats.add_modifier(Stats.ATTACK_SPEED, StatModifier.Mode.PERCENT, 0.5)
	check_near(hose.get_cooldown(), base_cd / 1.5, "attack speed shortens cooldown", 0.001)
	await free_game(game)


func test_enemy_damage_kill_and_rewards() -> void:
	var game := make_game()
	var ctx := game.ctx
	var kills_before := RunState.kills
	var enemy := ctx.enemies.spawn(load(DRY_ONE), Vector2(300, 0))
	check_eq(ctx.enemies.count(), 1, "spawned")
	check(not ctx.enemies.damage(enemy, enemy.hp - 1.0), "survives non-lethal damage")
	check(ctx.enemies.damage(enemy, 5.0), "dies on lethal damage")
	check_eq(ctx.enemies.count(), 0, "removed from active list")
	check_eq(RunState.kills, kills_before + 1, "kill counted")
	check(ctx.pickups.active.size() >= 1, "dropped a pickup")
	check(not ctx.enemies.damage(enemy, 5.0), "dead enemies ignore damage")
	await free_game(game)


func test_shield_absorbs_then_breaks() -> void:
	var game := make_game()
	var ctx := game.ctx
	var elite := ctx.enemies.spawn(load(BUREAUCRAT), Vector2(300, 0))
	var hp := elite.hp
	ctx.enemies.damage(elite, elite.shield - 5.0)
	check_near(elite.hp, hp, "shield soaks damage")
	ctx.enemies.damage(elite, 15.0)   # 5 breaks shield, 10 spills over
	check_near(elite.shield, 0.0, "shield broken")
	check_near(elite.hp, hp - 10.0, "overflow damage applied")
	await free_game(game)


func test_projectile_hits_and_pierces() -> void:
	var game := make_game()
	var ctx := game.ctx
	var data: EnemyData = load(DRY_ONE)
	var a := ctx.enemies.spawn(data, Vector2(200, 0))
	var b := ctx.enemies.spawn(data, Vector2(230, 0))
	await tree.process_frame   # let the grid pick them up
	var config: ProjectileConfig = load("res://resources/projectiles/water_droplet.tres")
	ctx.projectiles.spawn(config, Vector2(170, 0), Vector2.RIGHT, 1.0, 0.0, 1, 1.0, 1.0)
	for i in 30:
		await tree.process_frame
	check(a.hp < a.max_hp, "first enemy hit")
	check(b.hp < b.max_hp, "pierced through to second enemy")
	check_eq(ctx.projectiles.active.size(), 0, "projectile consumed after pierce budget")
	await free_game(game)


func test_xp_pickup_is_collected() -> void:
	var game := make_game()
	var ctx := game.ctx
	var xp_before := RunState.xp
	ctx.pickups.spawn(Pickup.Kind.XP, ctx.player.position + Vector2(12, 0), 1.0)
	for i in 60:
		await tree.process_frame
	check_eq(ctx.pickups.active.size(), 0, "pickup collected")
	check_eq(RunState.xp, xp_before + 1, "xp granted")
	await free_game(game)


func test_player_armor_and_death() -> void:
	var game := make_game()
	var player := game.ctx.player
	player.invulnerable = false
	player.stats.add_modifier(Stats.ARMOR, StatModifier.Mode.FLAT, 0.5)
	player.take_damage(20.0)
	check_near(player.health.health, 90.0, "armor halves damage")
	player.take_damage(20.0)
	check_near(player.health.health, 90.0, "i-frames block the immediate second hit")
	for i in 30:
		await tree.process_frame
	player.take_damage(1000.0)
	check(not player.alive, "player dies")
	await free_game(game)


func test_stage_data_is_sane() -> void:
	var stage: StageData = load("res://resources/stages/dry_wastelands.tres")
	check_near(stage.duration, 600.0, "10 minute stage")
	check(stage.final_boss != null and stage.final_boss.tier == EnemyData.Tier.BOSS, "has a boss")
	var types := {}
	var has_elite := false
	for wave in stage.waves:
		types[wave.enemy.id] = true
		check(wave.enemy.behavior != null, "%s has a behavior" % wave.enemy.id)
	for event in stage.events:
		has_elite = has_elite or event.enemy.tier == EnemyData.Tier.ELITE
	check(types.size() >= 3, "at least three basic enemy archetypes")
	check(has_elite, "has an elite event")
