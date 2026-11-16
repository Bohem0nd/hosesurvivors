class_name StatBlock
extends RefCounted
## A set of numeric stats with stackable modifiers.
## final = (base + sum(FLAT)) * (1 + sum(PERCENT)) * product(MULT)

signal changed(stat: StringName)

var _base: Dictionary = {}
var _flat: Dictionary = {}
var _pct: Dictionary = {}
var _mult: Dictionary = {}
var _cache: Dictionary = {}


func _init() -> void:
	for stat: StringName in Stats.DEFAULTS:
		_base[stat] = Stats.DEFAULTS[stat]


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_invalidate(stat)


func get_base(stat: StringName, default: float = 1.0) -> float:
	return _base.get(stat, default)


## Unknown stats (e.g. tag multipliers nobody has modified) resolve from `default`.
func get_stat(stat: StringName, default: float = 1.0) -> float:
	if _cache.has(stat):
		return _cache[stat]
	var value: float = (float(_base.get(stat, default)) + float(_flat.get(stat, 0.0))) \
			* (1.0 + float(_pct.get(stat, 0.0))) * float(_mult.get(stat, 1.0))
	_cache[stat] = value
	return value


func add_modifier(stat: StringName, mode: StatModifier.Mode, amount: float) -> void:
	match mode:
		StatModifier.Mode.FLAT:
			_flat[stat] = float(_flat.get(stat, 0.0)) + amount
		StatModifier.Mode.PERCENT:
			_pct[stat] = float(_pct.get(stat, 0.0)) + amount
		StatModifier.Mode.MULT:
			_mult[stat] = float(_mult.get(stat, 1.0)) * amount
	_invalidate(stat)


func apply(modifier: StatModifier) -> void:
	add_modifier(modifier.stat, modifier.mode, modifier.amount)


func _invalidate(stat: StringName) -> void:
	_cache.erase(stat)
	changed.emit(stat)
