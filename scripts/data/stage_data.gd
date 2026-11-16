class_name StageData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var duration: float = 600.0
@export var max_enemies: int = 350
@export var ground_texture: Texture2D
@export var ground_tint: Color = Color.WHITE
## Props scattered deterministically; weights[i] pairs with decor[i].
@export var decor: Array[Texture2D] = []
@export var decor_weights: Array[float] = []
@export var decor_per_chunk: int = 3
@export var music: AudioStream

@export_group("Spawning")
@export var waves: Array[SpawnWave] = []
@export var events: Array[StageEvent] = []
@export var final_boss: EnemyData
@export var boss_announcement: String
@export var boss_subtitle: String
@export var health_scale_per_minute: float = 0.15
@export var damage_scale_per_minute: float = 0.05
