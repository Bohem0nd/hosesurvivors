extends Node
## Centralised state for the current run: clock, score, XP/level. Reset per run.

var character: CharacterData
var stage: StageData
var active: bool = false
var time: float = 0.0
var kills: int = 0
var coins: int = 0
var level: int = 1
var xp: int = 0
var boss_phase: bool = false
var victory: bool = false


func start(p_character: CharacterData, p_stage: StageData) -> void:
	character = p_character
	stage = p_stage
	active = true
	time = 0.0
	kills = 0
	coins = 0
	level = 1
	xp = 0
	boss_phase = false
	victory = false
	Events.run_started.emit()
	Events.xp_changed.emit(xp, xp_required(level))
	Events.coins_changed.emit(coins)


## XP needed to go from `for_level` to the next one.
static func xp_required(for_level: int) -> int:
	var n := for_level - 1
	return int(5.0 + 5.0 * n + 0.55 * n * n)


func add_xp(amount: int) -> void:
	if not active:
		return
	xp += amount
	while xp >= xp_required(level):
		xp -= xp_required(level)
		level += 1
		Events.level_up.emit(level)
	Events.xp_changed.emit(xp, xp_required(level))


func add_coins(amount: int) -> void:
	coins += amount
	Events.coins_changed.emit(coins)


func register_kill() -> void:
	kills += 1


func finish(p_victory: bool) -> void:
	if not active:
		return
	active = false
	victory = p_victory
	SaveManager.record_run(victory, time, kills, level, coins)
	Events.run_ended.emit(victory)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]
