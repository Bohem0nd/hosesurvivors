class_name Weapon
extends Node2D
## Base class for weapon behaviors. Resolves effective stats from
## WeaponData + level bonuses + the owner's StatBlock; subclasses implement the
## attack pattern in _process and call the get_* helpers.

var data: WeaponData
var player: Player
var ctx: GameContext
var level: int = 1

var _bonus_damage: float = 0.0
var _bonus_cooldown: float = 1.0
var _bonus_count: int = 0
var _bonus_area: float = 0.0
var _bonus_knockback: float = 0.0
var _bonus_duration: float = 0.0
var _bonus_pierce: int = 0
var _bonus_range: float = 0.0


func setup(p_data: WeaponData, p_player: Player, p_ctx: GameContext) -> void:
	data = p_data
	player = p_player
	ctx = p_ctx
	_on_setup()


func _on_setup() -> void:
	pass


func level_up() -> void:
	if level >= data.max_level:
		return
	var bonus := next_level_bonus()
	level += 1
	_bonus_damage += float(bonus.get("damage", 0.0))
	_bonus_cooldown *= float(bonus.get("cooldown", 1.0))
	_bonus_count += int(bonus.get("projectile_count", 0))
	_bonus_area += float(bonus.get("area", 0.0))
	_bonus_knockback += float(bonus.get("knockback", 0.0))
	_bonus_duration += float(bonus.get("duration", 0.0))
	_bonus_pierce += int(bonus.get("pierce", 0))
	_bonus_range += float(bonus.get("range", 0.0))


## The bonus dictionary that the next level_up() will apply ({} at max level).
func next_level_bonus() -> Dictionary:
	var i := level - 1
	return data.level_bonuses[i] if i < data.level_bonuses.size() else {}


func get_damage() -> float:
	var mult := player.stats.get_stat(Stats.DAMAGE)
	for tag in data.tags:
		mult *= player.stats.get_stat(StringName("damage_" + tag), 1.0)
	return (data.damage + _bonus_damage) * mult


func get_cooldown() -> float:
	return data.cooldown * _bonus_cooldown * player.stats.get_stat(Stats.COOLDOWN) \
			/ maxf(0.1, player.stats.get_stat(Stats.ATTACK_SPEED))


func get_projectile_count() -> int:
	return data.projectile_count + _bonus_count + int(player.stats.get_stat(Stats.PROJECTILE_COUNT))


func get_area() -> float:
	return data.area * (1.0 + _bonus_area) * player.stats.get_stat(Stats.AREA)


func get_knockback() -> float:
	return data.knockback * (1.0 + _bonus_knockback) * player.stats.get_stat(Stats.KNOCKBACK)


func get_duration() -> float:
	return data.duration * (1.0 + _bonus_duration) * player.stats.get_stat(Stats.DURATION)


func get_pierce() -> int:
	return data.pierce + _bonus_pierce


func get_range() -> float:
	return data.attack_range * (1.0 + _bonus_range) * sqrt(player.stats.get_stat(Stats.AREA))
