class_name UpgradeData
extends Resource
## A passive (stat) upgrade or a consumable fallback offered on level-up.

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var max_level: int = 5
@export var weight: float = 1.0
@export var rarity: Rarity = Rarity.COMMON
## Applied once per level taken.
@export var modifiers: Array[StatModifier] = []
## Consumable effects (used by fallback offers; max_level 0 = unlimited).
@export var heal_amount: float = 0.0
@export var coin_amount: int = 0
