class_name StageEvent
extends Resource
## A one-off scripted moment: elite arrival, encirclement, boss.

enum Pattern { NEAR_PLAYER, ENCIRCLE }

@export var time: float = 0.0
@export var enemy: EnemyData
@export var count: int = 1
@export var pattern: Pattern = Pattern.NEAR_PLAYER
@export var announcement: String
@export var subtitle: String
@export var sfx: StringName
