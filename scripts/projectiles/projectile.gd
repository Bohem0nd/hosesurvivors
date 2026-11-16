class_name Projectile
extends Sprite2D
## Pooled projectile. Updated by ProjectileManager.

var config: ProjectileConfig
var velocity: Vector2
var damage: float
var knockback: float
var pierce_left: int
var life: float
var radius: float
var team: int
var index: int = -1
var hit_uids: PackedInt32Array = PackedInt32Array()
