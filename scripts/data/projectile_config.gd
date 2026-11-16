class_name ProjectileConfig
extends Resource
## Visual + physical description of a projectile type. Damage comes from the firer.

@export var texture: Texture2D
@export var speed: float = 300.0
@export var radius: float = 4.0
@export var lifetime: float = 0.6
@export var rotate_to_velocity: bool = true
@export var spin: float = 0.0
@export var hit_color: Color = Color(0.5, 0.8, 1.0)
@export var hit_particles: int = 3
@export var hit_sfx: StringName
@export var leaves_puddle: bool = false
