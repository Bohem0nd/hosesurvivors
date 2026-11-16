class_name UpgradeOffer
extends RefCounted
## One card on the level-up screen.

enum Kind { NEW_WEAPON, WEAPON_LEVEL, EVOLUTION, PASSIVE, CONSUMABLE }

var kind: Kind
var title: String
var description: String
var level_text: String
var icon: Texture2D
var weight: float = 1.0
var weapon: WeaponData
var upgrade: UpgradeData


func is_special() -> bool:
	return kind == Kind.EVOLUTION
