class_name EnemyBehavior
extends Resource
## Base movement/attack logic for an enemy archetype. One instance is shared by
## every enemy using it, so per-enemy state must live in `enemy.state`.


## Called once when an enemy using this behavior spawns.
func start(_enemy: Enemy, _ctx: GameContext) -> void:
	pass


## Returns the desired velocity for this frame.
## `dir`/`dist` are the precomputed direction and distance to the player.
func update(enemy: Enemy, _ctx: GameContext, dir: Vector2, _dist: float, _delta: float) -> Vector2:
	return dir * enemy.speed
