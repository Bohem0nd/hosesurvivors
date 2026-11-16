class_name AccelerateNearBehavior
extends EnemyBehavior
## Chases, and speeds up dramatically once within `trigger_radius` (The Thirsty).

@export var trigger_radius: float = 90.0
@export var speed_multiplier: float = 2.4
@export var ramp_time: float = 0.6


func update(enemy: Enemy, _ctx: GameContext, dir: Vector2, dist: float, delta: float) -> Vector2:
	var boost: float = enemy.state.get(&"boost", 0.0)
	var target := 1.0 if dist < trigger_radius else 0.0
	boost = move_toward(boost, target, delta / ramp_time)
	enemy.state[&"boost"] = boost
	return dir * enemy.speed * lerpf(1.0, speed_multiplier, boost)
