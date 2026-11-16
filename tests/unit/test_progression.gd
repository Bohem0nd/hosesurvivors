extends TestSuite


func test_xp_curve_is_increasing() -> void:
	var prev := 0
	for level in range(1, 60):
		var need := RunState.xp_required(level)
		check(need > prev, "xp_required(%d) should exceed previous" % level)
		prev = need
	check_eq(RunState.xp_required(1), 5, "first level-up cost")


func test_add_xp_handles_multiple_levels() -> void:
	var game := make_game()
	var levels: Array[int] = []
	var on_level := func(l: int) -> void: levels.append(l)
	Events.level_up.connect(on_level)
	var need := RunState.xp_required(1) + RunState.xp_required(2) + 1
	RunState.add_xp(need)
	Events.level_up.disconnect(on_level)
	check_eq(RunState.level, 3, "level")
	check_eq(RunState.xp, 1, "carry-over xp")
	check_eq(levels, [2, 3] as Array[int], "level_up signals")
	await free_game(game)


func test_offers_are_distinct_and_valid() -> void:
	var game := make_game()
	var ups := game.upgrades
	ups.rng.seed = 3
	for i in 200:
		var offers := ups.roll_offers(3)
		check_eq(offers.size(), 3, "three offers")
		var seen := {}
		for o in offers:
			check(not seen.has(o.title), "duplicate offer %s" % o.title)
			seen[o.title] = true
	await free_game(game)


func test_maxed_upgrades_never_offered_and_fallbacks_fill() -> void:
	var game := make_game()
	var ups := game.upgrades
	ups.rng.seed = 9
	var guard := 0
	# Keep taking the first real upgrade until none are left.
	while guard < 500:
		guard += 1
		var candidates := ups.build_candidates()
		if candidates.is_empty():
			break
		for o in candidates:
			if o.kind == UpgradeOffer.Kind.PASSIVE:
				check(ups.get_passive_level(o.upgrade.id) < o.upgrade.max_level, "maxed passive offered: %s" % o.title)
			elif o.kind == UpgradeOffer.Kind.WEAPON_LEVEL:
				var w := game.ctx.player.weapons.get_weapon(o.weapon.id)
				check(w != null and w.level < w.data.max_level, "maxed weapon offered: %s" % o.title)
		ups.apply(candidates[0])
	check(guard < 500, "upgrade pool should be exhaustible")
	check(ups.passive_levels.size() <= ups.pool.max_passives, "passive slot cap respected")
	var offers := ups.roll_offers(3)
	check(offers.size() >= 1, "fallbacks offered when pool is exhausted")
	for o in offers:
		check_eq(o.kind, UpgradeOffer.Kind.CONSUMABLE, "only consumables remain")
	await free_game(game)


func test_evolution_requirements() -> void:
	var game := make_game()
	var ups := game.upgrades
	var weapons := game.ctx.player.weapons
	var hose := weapons.get_weapon(&"holy_hose")
	check(hose != null, "Jon starts with the Holy Hose")
	check(not ups.can_evolve(hose), "cannot evolve at level 1")
	while hose.level < hose.data.max_level:
		weapons.level_up(&"holy_hose")
	check(not ups.can_evolve(hose), "max level alone is not enough")
	for o in ups.build_candidates():
		check(o.kind != UpgradeOffer.Kind.EVOLUTION, "no evolution offer before requirement met")
		check(not (o.kind == UpgradeOffer.Kind.WEAPON_LEVEL and o.weapon.id == &"holy_hose"), "maxed hose not offered")
		if o.kind == UpgradeOffer.Kind.PASSIVE and o.upgrade.id == hose.data.evolution_required_upgrade:
			ups.apply(o)
	check(ups.can_evolve(hose), "evolves once the required passive is owned")
	var evo: UpgradeOffer = null
	for o in ups.build_candidates():
		if o.kind == UpgradeOffer.Kind.EVOLUTION:
			evo = o
	check(evo != null, "evolution offered")
	if evo != null:
		ups.apply(evo)
		check(weapons.get_weapon(&"holy_hose") == null, "base weapon replaced")
		check(weapons.get_weapon(&"hose_of_judgment") != null, "evolved weapon owned")
		for o in ups.build_candidates():
			check(o.kind == UpgradeOffer.Kind.PASSIVE, "no weapon offers once evolved: %s" % o.title)
	await free_game(game)
