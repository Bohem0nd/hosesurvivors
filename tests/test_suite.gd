class_name TestSuite
extends Object
## Base class for test suites: tiny assertion helpers that record failures.

var tree: SceneTree
var host: Node
var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected <%s> but got <%s>" % [message, expected, actual])


func check_near(actual: float, expected: float, message: String = "", epsilon: float = 0.0001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s expected ~%s but got %s" % [message, expected, actual])


## Spawns a fresh Game scene with the player made invulnerable.
func make_game() -> Game:
	Router.pending_character = null
	Router.pending_stage = null
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	host.add_child(game)
	game.ctx.player.invulnerable = true
	game.ctx.player.input_override = func() -> Vector2: return Vector2.ZERO
	return game


func free_game(game: Game) -> void:
	tree.paused = false
	RunState.active = false
	game.queue_free()
	await tree.process_frame
