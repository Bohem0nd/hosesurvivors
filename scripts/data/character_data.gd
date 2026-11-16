class_name CharacterData
extends Resource
## Data-driven playable character. Passive logic lives in `passive_script`
## (a script extending PassiveAbility) so generic systems stay character-agnostic.

@export var id: StringName
@export var display_name: String
@export var title: String
@export_multiline var description: String
@export var sprite_sheet: Texture2D
@export var frame_count: int = 6
@export var idle_frames: Vector2i = Vector2i(0, 1)   # first, last
@export var walk_frames: Vector2i = Vector2i(2, 5)

@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 90.0
@export var damage_multiplier: float = 1.0
@export var starting_weapon: WeaponData
## Shown on the roster for characters whose weapon is not built yet.
@export var weapon_preview: String

@export_group("Passive")
@export var passive_name: String
@export_multiline var passive_description: String
@export var passive_script: Script
@export var passive_params: Dictionary = {}

@export_group("Unlock")
@export var implemented: bool = false
@export var unlocked_by_default: bool = false
@export var unlock_cost: int = 0
@export var unlock_hint: String
