class_name EnemyData
extends Resource
## Data-driven enemy archetype. Movement/attack logic is the `behavior` resource.

enum Tier { NORMAL, ELITE, BOSS }

@export var id: StringName
@export var display_name: String
@export var tier: Tier = Tier.NORMAL
@export var texture: Texture2D
@export var hframes: int = 2
@export var anim_fps: float = 4.0
@export var sprite_scale: float = 1.0
@export var flying: bool = false

@export_group("Stats")
@export var max_health: float = 10.0
@export var speed: float = 30.0
@export var damage: float = 8.0
@export var radius: float = 6.0
@export var knockback_resist: float = 0.0
@export var shield: float = 0.0
@export var shield_regen_delay: float = 4.0
@export var behavior: EnemyBehavior

@export_group("Rewards")
@export var xp_value: int = 1
@export var coin_chance: float = 0.02
@export var drops_crate: bool = false
@export var death_color: Color = Color(0.8, 0.65, 0.45)
