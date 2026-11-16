extends Node
## Minimal unit/integration test runner (no third-party framework).
##
##   godot --headless res://tests/run_tests.tscn
##
## Every script in SUITES extends TestSuite; each method named test_* is a test.
## Exit code is the number of failed tests.

const SUITES: Array[String] = [
	"res://tests/unit/test_stat_block.gd",
	"res://tests/unit/test_core.gd",
	"res://tests/unit/test_progression.gd",
	"res://tests/unit/test_gameplay.gd",
]


func _ready() -> void:
	SaveManager.persist = false
	SaveManager.load_game()
	await get_tree().process_frame
	var failed := 0
	var total := 0
	for path in SUITES:
		var suite: TestSuite = (load(path) as GDScript).new()
		suite.tree = get_tree()
		suite.host = self
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			suite.failures.clear()
			await suite.call(method_name)
			if suite.failures.is_empty():
				printerr("  ok    %s :: %s" % [path.get_file(), method_name])
			else:
				failed += 1
				printerr("  FAIL  %s :: %s" % [path.get_file(), method_name])
				for f in suite.failures:
					printerr("          ", f)
		suite.free()
	printerr("\n%d tests, %d failed" % [total, failed])
	printerr("RESULT: ", "PASS" if failed == 0 else "FAIL")
	get_tree().paused = false
	get_tree().quit(failed)
