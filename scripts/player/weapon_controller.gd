class_name WeaponController
extends Node2D
## Holds and manages the player's weapons. Weapons are instantiated from
## WeaponData.behavior, so adding a weapon type never touches this file.

signal weapons_changed

var player: Player
var ctx: GameContext
var weapons: Array[Weapon] = []


func setup(p_player: Player, p_ctx: GameContext) -> void:
	player = p_player
	ctx = p_ctx


func add_weapon(data: WeaponData) -> Weapon:
	var weapon: Weapon = data.behavior.new()
	add_child(weapon)
	weapon.setup(data, player, ctx)
	weapons.append(weapon)
	weapons_changed.emit()
	return weapon


func get_weapon(id: StringName) -> Weapon:
	for weapon in weapons:
		if weapon.data.id == id:
			return weapon
	return null


func level_up(id: StringName) -> void:
	var weapon := get_weapon(id)
	if weapon != null and weapon.level < weapon.data.max_level:
		weapon.level_up()
		weapons_changed.emit()


## Replaces a weapon with its evolved form.
func evolve(id: StringName) -> Weapon:
	var old := get_weapon(id)
	if old == null or old.data.evolves_into == null:
		return null
	var evolved_data := old.data.evolves_into
	weapons.erase(old)
	old.queue_free()
	var evolved := add_weapon(evolved_data)
	Events.weapon_evolved.emit(evolved_data)
	return evolved


func set_active(on: bool) -> void:
	for weapon in weapons:
		weapon.set_process(on)
