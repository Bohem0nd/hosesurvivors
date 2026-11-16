extends Node
## Headless end-to-end simulation of a run, driven by a simple bot.
##
##   godot --headless --fixed-fps 60 res://tests/sim_run.tscn -- [--god] [--bot=kite|wander|idle] [--max-time=900] [--seed=1] [--then-restart]
##
## --god  player cannot die (verifies the full 10-minute flow + boss + victory)
## --then-restart  after the run ends, start a second run and play 20 s of it
## Bot modes are described in tests/test_bot.gd.
## Exits 0 if the run reached an end screen (and, with --god, was a victory).

var game: Game
var god := false
var bot := "kite"
var max_time := 900.0
var sim_time := 0.0
var frames := 0
var peak_enemies := 0
var peak_projectiles := 0
var worst_frame_ms := 0.0
var total_ms := 0.0
var last_report := -1
var picks: Array[String] = []
var started := false
var finished := false
var _last_tick := 0
var _boss: Enemy
var damage_taken := 0.0
var then_restart := false
var _restart_t := -1.0
var _first_game_id := 0
var min_hp_ratio := 1.0


func _ready() -> void:
	# Re-parent to the root so this runner survives the scene change.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Detach from "current scene" status so this runner survives the scene change.
	(func() -> void: get_tree().current_scene = null).call_deferred()
	for arg in OS.get_cmdline_user_args():
		if arg == "--god":
			god = true
		elif arg.begins_with("--bot="):
			bot = arg.get_slice("=", 1)
		elif arg == "--then-restart":
			then_restart = true
		elif arg.begins_with("--max-time="):
			max_time = float(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			seed(int(arg.get_slice("=", 1)))
	SaveManager.persist = false
	SaveManager.load_game()


func _process(delta: float) -> void:
	if not started:
		if get_tree().current_scene == self:
			return
		started = true
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	if game == null:
		game = get_tree().current_scene as Game
		if game == null:
			return
		game.ctx.player.invulnerable = god
		game.ctx.player.input_override = _bot_input
		game.level_up_screen.offer_chosen.connect(func(o: UpgradeOffer) -> void: picks.append(o.title))
		Events.run_ended.connect(func(_v: bool) -> void: finished = true)
		Events.boss_spawned.connect(func(e: Enemy) -> void: _boss = e)
		Events.player_damaged.connect(func(a: float) -> void: damage_taken += a)
		_last_tick = Time.get_ticks_usec()
		return

	var now := Time.get_ticks_usec()
	var ms := float(now - _last_tick) / 1000.0
	_last_tick = now
	frames += 1
	if not get_tree().paused:
		sim_time += delta
		total_ms += ms
		worst_frame_ms = maxf(worst_frame_ms, ms)
	var ctx := game.ctx
	min_hp_ratio = minf(min_hp_ratio, ctx.player.health.health / ctx.player.health.max_health)
	peak_enemies = maxi(peak_enemies, ctx.enemies.count())
	peak_projectiles = maxi(peak_projectiles, ctx.projectiles.active.size())

	# Bot picks the first card whenever the level-up screen is open.
	if game.level_up_screen.visible:
		var cards := game.level_up_screen._cards
		if cards.get_child_count() > 0:
			game.level_up_screen._open_time = 0
			(cards.get_child(TestBot.choose_card(game.level_up_screen.current_offers)) as Button).pressed.emit()

	var rs := RunState
	var minute := int(sim_time / 30.0)
	if minute != last_report:
		last_report = minute
		_log("[sim] t=%s (+%ds) lvl=%d kills=%d enemies=%d proj=%d hp=%d/%d pickups=%d boss_hp=%d" % [
			rs.format_time(rs.time), int(sim_time - rs.time), rs.level, rs.kills, ctx.enemies.count(),
			ctx.projectiles.active.size(), ctx.player.health.health, ctx.player.health.max_health,
			ctx.pickups.active.size(), _boss.hp if _boss != null and _boss.alive else 0])

	if finished and then_restart:
		_restart_check(delta)
		return
	if finished or sim_time > max_time:
		_report()
		set_process(false)


## Verifies "the game can be restarted without errors": new Game instance, clean
## RunState, and the second run actually progresses.
func _restart_check(delta: float) -> void:
	if _restart_t < 0.0:
		_restart_t = 0.0
		_first_game_id = game.get_instance_id()
		_log("[sim] run ended (victory=%s) - restarting" % RunState.victory)
		Router.start_run(RunState.character, RunState.stage)
		return
	_restart_t += delta
	var current := get_tree().current_scene as Game
	if current != null and current.get_instance_id() != _first_game_id and current.ctx.player.input_override.is_null():
		game = current
		game.ctx.player.input_override = _bot_input
	if _restart_t > 25.0:
		var ok: bool = current != null and current.get_instance_id() != _first_game_id \
				and RunState.active and RunState.time > 15.0 and RunState.kills > 0 and not get_tree().paused
		_log("restart check: new_game=%s active=%s time=%.1f kills=%d" % [
			current != null and current.get_instance_id() != _first_game_id, RunState.active, RunState.time, RunState.kills])
		_log("RESULT: ", "PASS" if ok else "FAIL")
		set_process(false)
		get_tree().quit(0 if ok else 1)


func _bot_input() -> Vector2:
	return TestBot.input(bot, game.ctx, sim_time)


func _report() -> void:
	var rs := RunState
	var ok: bool = finished and (rs.victory or not god)
	_log("---- SIM RESULT ----")
	_log("finished=%s victory=%s time=%s level=%d kills=%d coins=%d" % [finished, rs.victory, rs.format_time(rs.time), rs.level, rs.kills, rs.coins])
	_log("peak_enemies=%d peak_projectiles=%d frames=%d avg_frame_ms=%.2f worst_frame_ms=%.1f" % [
		peak_enemies, peak_projectiles, frames, total_ms / maxf(1.0, frames), worst_frame_ms])
	_log("damage_taken=%d min_hp_ratio=%.2f" % [damage_taken, min_hp_ratio])
	_log("upgrades taken: ", ", ".join(picks))
	_log("RESULT: ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


## stderr is unbuffered, so progress is visible even if the run is killed.
func _log(a: Variant, b: Variant = "") -> void:
	printerr(str(a), str(b))
