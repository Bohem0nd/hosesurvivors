extends TestSuite


func test_defaults_present() -> void:
	var s := StatBlock.new()
	check_near(s.get_stat(Stats.MAX_HEALTH), 100.0, "max_health")
	check_near(s.get_stat(Stats.DAMAGE), 1.0, "damage")
	check_near(s.get_stat(Stats.PROJECTILE_COUNT), 0.0, "projectile_count")


func test_unknown_stat_uses_default() -> void:
	var s := StatBlock.new()
	check_near(s.get_stat(&"damage_water", 1.0), 1.0, "tag multiplier")
	check_near(s.get_stat(&"mystery", 0.0), 0.0, "zero default")


func test_modifier_stacking_order() -> void:
	var s := StatBlock.new()
	s.set_base(Stats.DAMAGE, 10.0)
	s.add_modifier(Stats.DAMAGE, StatModifier.Mode.FLAT, 5.0)      # 15
	s.add_modifier(Stats.DAMAGE, StatModifier.Mode.PERCENT, 0.2)   # x1.2
	s.add_modifier(Stats.DAMAGE, StatModifier.Mode.PERCENT, 0.3)   # x1.5 total (additive)
	s.add_modifier(Stats.DAMAGE, StatModifier.Mode.MULT, 0.5)      # x0.5
	check_near(s.get_stat(Stats.DAMAGE), 15.0 * 1.5 * 0.5, "(base+flat)*(1+pct)*mult")


func test_cache_invalidates_and_signals() -> void:
	var s := StatBlock.new()
	var seen: Array[StringName] = []
	s.changed.connect(func(stat: StringName) -> void: seen.append(stat))
	check_near(s.get_stat(Stats.AREA), 1.0, "before")
	s.add_modifier(Stats.AREA, StatModifier.Mode.PERCENT, 0.15)
	check_near(s.get_stat(Stats.AREA), 1.15, "after")
	check(seen.has(Stats.AREA), "changed signal emitted")


func test_tag_modifier_on_undefined_stat() -> void:
	var s := StatBlock.new()
	s.add_modifier(&"damage_water", StatModifier.Mode.PERCENT, 0.2)
	check_near(s.get_stat(&"damage_water", 1.0), 1.2, "tag percent")
