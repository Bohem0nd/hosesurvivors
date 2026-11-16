extends PassiveAbility
## Jon Hose - "Pressure Builds": damage and knockback rise the longer he survives.
## params: interval (s), step (fraction per tick), cap (max total fraction)

var _timer: float = 0.0
var _total: float = 0.0


func _process(delta: float) -> void:
	if not player.alive:
		return
	var cap: float = params.get("cap", 0.6)
	if _total >= cap:
		return
	_timer += delta
	var interval: float = params.get("interval", 10.0)
	if _timer >= interval:
		_timer -= interval
		var step: float = minf(params.get("step", 0.01), cap - _total)
		_total += step
		player.stats.add_modifier(Stats.DAMAGE, StatModifier.Mode.PERCENT, step)
		player.stats.add_modifier(Stats.KNOCKBACK, StatModifier.Mode.PERCENT, step)


func get_status_text() -> String:
	return "PRESSURE +%d%%" % roundi(_total * 100.0)
