class_name SpatialGrid
extends RefCounted
## Uniform hash grid over enemies. Rebuilt once per frame by EnemyManager and
## used for projectile hits, weapon targeting and enemy separation.

var cell_size: float
var _inv: float
var _cells: Dictionary = {}  # Vector2i -> Array[Enemy]
var _empty: Array[Enemy] = []


func _init(p_cell_size: float = 32.0) -> void:
	cell_size = p_cell_size
	_inv = 1.0 / p_cell_size


func clear() -> void:
	# The arena is unbounded, so drop stale buckets once in a while.
	if _cells.size() > 4096:
		_cells.clear()
		return
	for bucket: Array in _cells.values():
		bucket.clear()


func insert(enemy: Enemy) -> void:
	var key := Vector2i(floori(enemy.position.x * _inv), floori(enemy.position.y * _inv))
	var bucket: Variant = _cells.get(key)
	if bucket == null:
		var created: Array[Enemy] = []
		created.append(enemy)
		_cells[key] = created
	else:
		(bucket as Array[Enemy]).append(enemy)


func bucket_at(pos: Vector2) -> Array[Enemy]:
	return _cells.get(Vector2i(floori(pos.x * _inv), floori(pos.y * _inv)), _empty)


## Appends every enemy whose body overlaps the circle to `out`.
func query_circle(pos: Vector2, radius: float, out: Array[Enemy], max_enemy_radius: float = 32.0) -> void:
	var reach := radius + max_enemy_radius
	var x0 := floori((pos.x - reach) * _inv)
	var x1 := floori((pos.x + reach) * _inv)
	var y0 := floori((pos.y - reach) * _inv)
	var y1 := floori((pos.y + reach) * _inv)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var bucket: Variant = _cells.get(Vector2i(cx, cy))
			if bucket == null:
				continue
			for enemy: Enemy in bucket:
				var r := radius + enemy.radius
				if enemy.position.distance_squared_to(pos) <= r * r:
					out.append(enemy)


## Nearest living enemy within max_distance, or null. Searches ring by ring so
## the common case (something close) stays cheap.
func nearest(pos: Vector2, max_distance: float) -> Enemy:
	var best: Enemy = null
	var best_d2 := max_distance * max_distance
	var center := Vector2i(floori(pos.x * _inv), floori(pos.y * _inv))
	var max_ring := ceili(max_distance * _inv)
	for ring in range(0, max_ring + 1):
		# Once something is found, one more ring guarantees correctness.
		if best != null and float(ring - 1) * cell_size > sqrt(best_d2):
			break
		for cy in range(center.y - ring, center.y + ring + 1):
			var edge_row := cy == center.y - ring or cy == center.y + ring
			var step := 1 if edge_row else maxi(ring * 2, 1)
			for cx in range(center.x - ring, center.x + ring + 1, step):
				var bucket: Variant = _cells.get(Vector2i(cx, cy))
				if bucket == null:
					continue
				for enemy: Enemy in bucket:
					var d2 := enemy.position.distance_squared_to(pos)
					if d2 < best_d2:
						best_d2 = d2
						best = enemy
	return best
