class_name WobbleBehavior
extends EnemyBehavior
## Chases while weaving side to side (floating paperwork, corrupted memes).

@export var amplitude: float = 0.8   # sideways speed as a fraction of forward speed
@export var frequency: float = 3.0


func start(enemy: Enemy, _ctx: GameContext) -> void:
	enemy.state[&"phase"] = randf() * TAU


func update(enemy: Enemy, _ctx: GameContext, dir: Vector2, _dist: float, delta: float) -> Vector2:
	var phase: float = enemy.state.get(&"phase", 0.0) + frequency * delta
	enemy.state[&"phase"] = phase
	return (dir + dir.orthogonal() * sin(phase) * amplitude) * enemy.speed
