extends Node
## Captures screenshots of any scene for visual review (needs a display, e.g. xvfb-run).
##
##   xvfb-run -a godot --fixed-fps 60 res://tests/screenshot.tscn -- \
##       --scene=res://scenes/game.tscn --at=5,30,90 --out=/tmp/shots [--god] [--bot=kite|wander|idle] [--skip-to=590] [--hold-levelup] [--pause-at-end]
##
## In the game scene a bot plays and auto-picks upgrades.

var scene_path := "res://scenes/ui/main_menu.tscn"
var out_dir := "user://shots"
var times: Array[float] = [1.0]
var god := false
var skip_to := -1.0
var hold_levelup := false
var bot := "kite"
var t := 0.0
var started := false
var game: Game
var shot_index := 0
var pause_at_end := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--at="):
			times.clear()
			for part in arg.get_slice("=", 1).split(","):
				times.append(float(part))
		elif arg.begins_with("--skip-to="):
			skip_to = float(arg.get_slice("=", 1))
		elif arg == "--god":
			god = true
		elif arg.begins_with("--bot="):
			bot = arg.get_slice("=", 1)
		elif arg == "--pause-at-end":
			pause_at_end = true
		elif arg == "--hold-levelup":
			hold_levelup = true
	SaveManager.persist = false
	SaveManager.load_game()
	DirAccess.make_dir_recursive_absolute(out_dir)
	(func() -> void: get_tree().current_scene = null).call_deferred()


func _process(delta: float) -> void:
	if not started:
		if get_tree().current_scene == self:
			return
		started = true
		get_tree().change_scene_to_file(scene_path)
		return
	t += delta
	if game == null and get_tree().current_scene is Game:
		game = get_tree().current_scene
		game.ctx.player.invulnerable = god
		game.ctx.player.input_override = _bot
		if skip_to > 0.0:
			RunState.time = skip_to
	if game != null and game.level_up_screen.visible and not (hold_levelup and shot_index == times.size() - 1):
		var cards := game.level_up_screen._cards
		if cards.get_child_count() > 0:
			game.level_up_screen._open_time = 0
			(cards.get_child(TestBot.choose_card(game.level_up_screen.current_offers)) as Button).pressed.emit()
	if pause_at_end and game != null and shot_index == times.size() - 1 and t >= times[shot_index] - 0.5 \
			and not game.pause_menu.visible and not get_tree().paused:
		game.pause_menu.open()
	if shot_index < times.size() and t >= times[shot_index]:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/shot_%02d.png" % [out_dir, shot_index]
		img.save_png(path)
		printerr("saved ", path)
		shot_index += 1
		if shot_index >= times.size():
			get_tree().quit()


func _bot() -> Vector2:
	return TestBot.input(bot, game.ctx, t)
