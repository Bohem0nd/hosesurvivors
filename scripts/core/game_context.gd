class_name GameContext
extends RefCounted
## References to the live systems of a run. Passed explicitly to anything that
## needs them (weapons, behaviors, passives) instead of scene-tree lookups.

var player: Player
var enemies: EnemyManager
var projectiles: ProjectileManager
var pickups: PickupManager
var particles: ParticleField
var rings: RingField
var numbers: DamageNumbers
var camera: GameCamera
var hazards: Node2D
var stage: StageData
