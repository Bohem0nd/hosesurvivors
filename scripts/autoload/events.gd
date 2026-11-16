extends Node
## Global signal bus. Systems talk through here instead of holding references to each other.

signal run_started
signal run_ended(victory: bool)

signal player_damaged(amount: float)
signal player_healed(amount: float)
signal player_died

signal enemy_killed(data: EnemyData, position: Vector2)
signal boss_spawned(enemy: Enemy)
signal boss_defeated(data: EnemyData)

signal xp_changed(xp: int, required: int)
signal level_up(new_level: int)
signal coins_changed(coins: int)
signal crate_collected
signal upgrade_applied(offer: UpgradeOffer)
signal weapon_evolved(weapon: WeaponData)

signal announcement(title: String, subtitle: String, is_boss: bool)
