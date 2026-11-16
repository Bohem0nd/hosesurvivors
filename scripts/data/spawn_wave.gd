class_name SpawnWave
extends Resource
## A continuous trickle of one enemy type between two timestamps.
## Interval and batch size interpolate from *_start to *_end across the window.

@export var enemy: EnemyData
@export var start_time: float = 0.0
@export var end_time: float = 600.0
@export var interval_start: float = 1.0
@export var interval_end: float = 0.5
@export var count_start: int = 1
@export var count_end: int = 2
## Spawn the whole batch as one tight cluster instead of scattered around the ring.
@export var cluster: bool = false
