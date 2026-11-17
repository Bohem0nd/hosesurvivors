class_name SpawnDirector
extends Node
## Turns StageData (waves + scripted events + final boss) into enemy spawns,
## and ramps enemy health/damage over time.

const SPAWN_MARGIN := 24.0
const BOSS_PHASE_INTERVAL_SCALE := 2.5

var ctx: GameContext
var stage: StageData
var boss_spawned: bool = false

var _wave_timers: PackedFloat32Array = PackedFloat32Array()
var _events: Array[StageEvent] = []
var _next_event: int = 0


func setup(p_ctx: GameContext, p_stage: StageData) -> void:
	ctx = p_ctx
	stage = p_stage
	_wave_timers.resize(stage.waves.size())
	_wave_timers.fill(0.0)
	_events = stage.events.duplicate()
	_events.sort_custom(func(a: StageEvent, b: StageEvent) -> bool: return a.time < b.time)


func _process(delta: float) -> void:
	if ctx == null or not RunState.active or not ctx.player.alive:
		return
	var t := RunState.time
	var minutes := t / 60.0
	ctx.enemies.health_scale = 1.0 + stage.health_scale_per_minute * minutes
	ctx.enemies.damage_scale = 1.0 + stage.damage_scale_per_minute * minutes

	while _next_event < _events.size() and _events[_next_event].time <= t:
		_run_event(_events[_next_event])
		_next_event += 1

	if t >= stage.duration and not boss_spawned:
		_spawn_boss()

	for i in stage.waves.size():
		var wave := stage.waves[i]
		if t < wave.start_time or t > wave.end_time:
			continue
		_wave_timers[i] -= delta
		if _wave_timers[i] > 0.0:
			continue
		var f := clampf(inverse_lerp(wave.start_time, wave.end_time, t), 0.0, 1.0)
		var interval := lerpf(wave.interval_start, wave.interval_end, f)
		if RunState.boss_phase:
			interval *= BOSS_PHASE_INTERVAL_SCALE
		_wave_timers[i] = interval
		_spawn_batch(wave.enemy, roundi(lerpf(wave.count_start, wave.count_end, f)), wave.cluster)


func _spawn_batch(enemy: EnemyData, count: int, cluster: bool) -> void:
	var anchor := edge_position()
	for i in count:
		if ctx.enemies.count() >= stage.max_enemies:
			return
		var pos := anchor + Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0)) if cluster else edge_position()
		ctx.enemies.spawn(enemy, pos)


func _run_event(event: StageEvent) -> void:
	if event.announcement != "":
		Events.announcement.emit(event.announcement, event.subtitle, false)
	AudioManager.play(event.sfx)
	match event.pattern:
		StageEvent.Pattern.ENCIRCLE:
			var view_half := _view_half()
			for i in event.count:
				var ang := TAU * float(i) / float(event.count)
				ctx.enemies.spawn(event.enemy, ctx.player.position
						+ Vector2(cos(ang) * (view_half.x + 30.0), sin(ang) * (view_half.y + 30.0)))
		_:
			for i in event.count:
				ctx.enemies.spawn(event.enemy, edge_position())


func _spawn_boss() -> void:
	boss_spawned = true
	RunState.boss_phase = true
	if stage.final_boss == null:
		return
	Events.announcement.emit(stage.boss_announcement, stage.boss_subtitle, true)
	AudioManager.play(&"boss_intro")
	ctx.camera.shake(5.0)
	ctx.enemies.spawn(stage.final_boss, ctx.player.position + Vector2(0.0, -(_view_half().y + 40.0)))


## A random point just outside the visible screen around the player.
func edge_position() -> Vector2:
	var half := _view_half() + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var p: Vector2
	if randf() < half.x / (half.x + half.y):
		p = Vector2(randf_range(-half.x, half.x), half.y * (1.0 if randf() < 0.5 else -1.0))
	else:
		p = Vector2(half.x * (1.0 if randf() < 0.5 else -1.0), randf_range(-half.y, half.y))
	return ctx.player.position + p


## Half the visible area; wider or taller screens see more of the world (see Device).
func _view_half() -> Vector2:
	return Device.view_size() * 0.5
