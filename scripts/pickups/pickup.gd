class_name Pickup
extends Sprite2D
## Pooled pickup instance. Updated by PickupManager.

enum Kind { XP, COIN, HEAL, CRATE, MAGNET }

var kind: Kind
var value: float
var attracted: bool = false
var speed: float = 0.0
var age: float = 0.0
var index: int = -1
var scatter: Vector2 = Vector2.ZERO
