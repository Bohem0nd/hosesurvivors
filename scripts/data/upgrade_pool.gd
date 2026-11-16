class_name UpgradePool
extends Resource
## Everything that can show up on the level-up screen.

@export var weapons: Array[WeaponData] = []
@export var passives: Array[UpgradeData] = []
## Offered only when nothing else is available.
@export var fallbacks: Array[UpgradeData] = []
@export var max_weapons: int = 6
@export var max_passives: int = 6
