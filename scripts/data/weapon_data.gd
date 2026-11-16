class_name WeaponData
extends Resource
## Data-driven weapon definition. `behavior` is a script extending Weapon that
## implements the attack pattern; everything else is tuning.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var behavior: Script
@export var tags: Array[StringName] = []
@export var projectile: ProjectileConfig
@export var visual_texture: Texture2D

@export_group("Base stats")
@export var damage: float = 5.0
@export var cooldown: float = 1.0
@export var projectile_count: int = 1
@export var attack_range: float = 150.0
@export var area: float = 1.0
@export var knockback: float = 40.0
@export var duration: float = 0.5
@export var pierce: int = 0

@export_group("Progression")
@export var max_level: int = 6
## One entry per level above 1. Keys: desc, damage (+flat), cooldown (xmult),
## projectile_count (+), area (+pct), knockback (+pct), duration (+pct), pierce (+).
@export var level_bonuses: Array[Dictionary] = []
@export var is_evolution: bool = false
@export var evolves_into: WeaponData
## Passive upgrade id that must be owned to evolve (empty = only max level needed).
@export var evolution_required_upgrade: StringName

@export_group("Feedback")
@export var fire_sfx: StringName
## Behaviour-specific tuning, read by the behavior script.
@export var params: Dictionary = {}
