extends TestSuite


func _enemies(n: int, spread: float, rng: RandomNumberGenerator) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for i in n:
		var e := Enemy.new()
		e.position = Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
		e.radius = rng.randf_range(4.0, 10.0)
		e.uid = i
		out.append(e)
	return out


func test_grid_query_matches_brute_force() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var enemies := _enemies(300, 400.0, rng)
	var grid := SpatialGrid.new(32.0)
	for e in enemies:
		grid.insert(e)
	for trial in 40:
		var pos := Vector2(rng.randf_range(-400, 400), rng.randf_range(-400, 400))
		var radius := rng.randf_range(2.0, 60.0)
		var got: Array[Enemy] = []
		grid.query_circle(pos, radius, got)
		var expected := 0
		for e in enemies:
			if e.position.distance_to(pos) <= radius + e.radius:
				expected += 1
		check_eq(got.size(), expected, "query_circle trial %d" % trial)
	for e in enemies:
		e.free()


func test_grid_nearest_matches_brute_force() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var enemies := _enemies(200, 500.0, rng)
	var grid := SpatialGrid.new(32.0)
	for e in enemies:
		grid.insert(e)
	for trial in 40:
		var pos := Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500))
		var max_d := rng.randf_range(20.0, 300.0)
		var best: Enemy = null
		var best_d := max_d
		for e in enemies:
			var d := e.position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = e
		check(grid.nearest(pos, max_d) == best, "nearest trial %d" % trial)
	for e in enemies:
		e.free()


func test_grid_clear() -> void:
	var grid := SpatialGrid.new(32.0)
	var e := Enemy.new()
	grid.insert(e)
	grid.clear()
	check(grid.nearest(Vector2.ZERO, 100.0) == null, "empty after clear")
	e.free()


func test_object_pool_reuses_nodes() -> void:
	var parent := Node.new()
	host.add_child(parent)
	var pool := ObjectPool.new(parent, func() -> Node: return Node2D.new(), 3)
	check_eq(pool.total_created, 3, "prewarm")
	var a := pool.acquire()
	var b := pool.acquire()
	check_eq(pool.free_count(), 1, "free after two acquires")
	pool.release(a)
	pool.release(b)
	var c := pool.acquire()
	check(c == a or c == b, "acquire returns a released node")
	check_eq(pool.total_created, 3, "no new allocations")
	for i in 5:
		pool.acquire()
	check_eq(pool.total_created, 6, "grows on demand")
	parent.free()


func test_health_component() -> void:
	var h := HealthComponent.new()
	h.setup(100.0)
	var died := [false]
	h.died.connect(func() -> void: died[0] = true)
	h.damage(30.0)
	check_near(h.health, 70.0, "after damage")
	check_near(h.heal(50.0), 30.0, "heal clamps to max")
	h.set_max(120.0)
	check_near(h.health, 120.0, "raising max grants the difference")
	h.damage(500.0)
	check(died[0] and h.is_dead(), "dies at zero")
	check_near(h.heal(10.0), 0.0, "no healing the dead")
	h.free()
