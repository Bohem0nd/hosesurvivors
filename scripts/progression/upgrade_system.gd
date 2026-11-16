class_name UpgradeSystem
extends RefCounted
## Builds level-up offers and applies the chosen one.
## Offers are weighted, never repeat within a roll, and never include maxed-out
## or otherwise invalid options. Evolutions appear once their requirements are met.

const WEIGHT_WEAPON_LEVEL := 1.6
const WEIGHT_NEW_WEAPON := 1.2
const WEIGHT_EVOLUTION := 1000.0  # effectively guaranteed once available

var pool: UpgradePool
var player: Player
var passive_levels: Dictionary = {}  # StringName -> int
var rng := RandomNumberGenerator.new()


func _init(p_pool: UpgradePool, p_player: Player) -> void:
	pool = p_pool
	player = p_player
	rng.randomize()


func get_passive_level(id: StringName) -> int:
	return passive_levels.get(id, 0)


func can_evolve(weapon: Weapon) -> bool:
	var data := weapon.data
	if data.evolves_into == null or weapon.level < data.max_level:
		return false
	return data.evolution_required_upgrade == &"" or get_passive_level(data.evolution_required_upgrade) > 0


func build_candidates() -> Array[UpgradeOffer]:
	var out: Array[UpgradeOffer] = []
	var owned := player.weapons.weapons
	var owned_ids: Dictionary = {}
	for weapon in owned:
		owned_ids[weapon.data.id] = true
		if can_evolve(weapon):
			out.append(_evolution_offer(weapon))
		elif weapon.level < weapon.data.max_level:
			out.append(_weapon_level_offer(weapon))

	if owned.size() < pool.max_weapons:
		for data in pool.weapons:
			if data.is_evolution or owned_ids.has(data.id) or _owns_evolution_of(data, owned_ids):
				continue
			out.append(_new_weapon_offer(data))

	var slots_full := passive_levels.size() >= pool.max_passives
	for upgrade in pool.passives:
		var lvl := get_passive_level(upgrade.id)
		if lvl >= upgrade.max_level or (lvl == 0 and slots_full):
			continue
		out.append(_passive_offer(upgrade, lvl))
	return out


## Picks up to `count` distinct offers by weight; pads with fallbacks if needed.
func roll_offers(count: int = 3) -> Array[UpgradeOffer]:
	var candidates := build_candidates()
	var picked: Array[UpgradeOffer] = []
	while picked.size() < count and not candidates.is_empty():
		var total := 0.0
		for c in candidates:
			total += c.weight
		var roll := rng.randf() * total
		var chosen := candidates.size() - 1
		for i in candidates.size():
			roll -= candidates[i].weight
			if roll <= 0.0:
				chosen = i
				break
		picked.append(candidates[chosen])
		candidates.remove_at(chosen)
	var f := 0
	while picked.size() < count and f < pool.fallbacks.size():
		picked.append(_consumable_offer(pool.fallbacks[f]))
		f += 1
	return picked


func apply(offer: UpgradeOffer) -> void:
	match offer.kind:
		UpgradeOffer.Kind.NEW_WEAPON:
			player.weapons.add_weapon(offer.weapon)
		UpgradeOffer.Kind.WEAPON_LEVEL:
			player.weapons.level_up(offer.weapon.id)
		UpgradeOffer.Kind.EVOLUTION:
			player.weapons.evolve(offer.weapon.id)
		UpgradeOffer.Kind.PASSIVE:
			passive_levels[offer.upgrade.id] = get_passive_level(offer.upgrade.id) + 1
			for modifier in offer.upgrade.modifiers:
				player.stats.apply(modifier)
		UpgradeOffer.Kind.CONSUMABLE:
			if offer.upgrade.heal_amount > 0.0:
				player.heal(offer.upgrade.heal_amount)
			if offer.upgrade.coin_amount > 0:
				RunState.add_coins(offer.upgrade.coin_amount)
	Events.upgrade_applied.emit(offer)


func _owns_evolution_of(data: WeaponData, owned_ids: Dictionary) -> bool:
	return data.evolves_into != null and owned_ids.has(data.evolves_into.id)


func _weapon_level_offer(weapon: Weapon) -> UpgradeOffer:
	var o := UpgradeOffer.new()
	o.kind = UpgradeOffer.Kind.WEAPON_LEVEL
	o.weapon = weapon.data
	o.title = weapon.data.display_name
	o.icon = weapon.data.icon
	o.level_text = "LV %d > %d" % [weapon.level, weapon.level + 1]
	o.description = str(weapon.next_level_bonus().get("desc", "Improves the weapon."))
	o.weight = WEIGHT_WEAPON_LEVEL
	return o


func _new_weapon_offer(data: WeaponData) -> UpgradeOffer:
	var o := UpgradeOffer.new()
	o.kind = UpgradeOffer.Kind.NEW_WEAPON
	o.weapon = data
	o.title = data.display_name
	o.icon = data.icon
	o.level_text = "NEW WEAPON"
	o.description = data.description
	o.weight = WEIGHT_NEW_WEAPON
	return o


func _evolution_offer(weapon: Weapon) -> UpgradeOffer:
	var evolved := weapon.data.evolves_into
	var o := UpgradeOffer.new()
	o.kind = UpgradeOffer.Kind.EVOLUTION
	o.weapon = weapon.data
	o.title = evolved.display_name
	o.icon = evolved.icon
	o.level_text = "EVOLUTION!"
	o.description = evolved.description
	o.weight = WEIGHT_EVOLUTION
	return o


func _passive_offer(upgrade: UpgradeData, current_level: int) -> UpgradeOffer:
	var o := UpgradeOffer.new()
	o.kind = UpgradeOffer.Kind.PASSIVE
	o.upgrade = upgrade
	o.title = upgrade.display_name
	o.icon = upgrade.icon
	o.level_text = "NEW" if current_level == 0 else "LV %d > %d" % [current_level, current_level + 1]
	o.description = upgrade.description
	o.weight = upgrade.weight
	return o


func _consumable_offer(upgrade: UpgradeData) -> UpgradeOffer:
	var o := UpgradeOffer.new()
	o.kind = UpgradeOffer.Kind.CONSUMABLE
	o.upgrade = upgrade
	o.title = upgrade.display_name
	o.icon = upgrade.icon
	o.level_text = "BONUS"
	o.description = upgrade.description
	return o
