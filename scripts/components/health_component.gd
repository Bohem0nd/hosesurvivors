class_name HealthComponent
extends Node
## Reusable health pool with signals. (Regular enemies keep raw floats for speed;
## this is for the player and any future one-off actors.)

signal changed(health: float, max_health: float)
signal damaged(amount: float)
signal died

var max_health: float = 100.0
var health: float = 100.0


func setup(p_max: float) -> void:
	max_health = p_max
	health = p_max
	changed.emit(health, max_health)


func is_dead() -> bool:
	return health <= 0.0


func damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	health = maxf(0.0, health - amount)
	damaged.emit(amount)
	changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> float:
	if is_dead():
		return 0.0
	var before := health
	health = minf(max_health, health + amount)
	if health != before:
		changed.emit(health, max_health)
	return health - before


## Raising the cap also grants the difference as health.
func set_max(new_max: float) -> void:
	var diff := new_max - max_health
	max_health = new_max
	health = clampf(health + maxf(diff, 0.0), 0.0, max_health)
	changed.emit(health, max_health)
