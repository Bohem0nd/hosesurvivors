extends Control
## Title screen.

const JON := preload("res://assets/sprites/characters/jon_hose.png")
const NOZZLE := preload("res://assets/sprites/weapons/hose_nozzle.png")
const TAGLINES := [
	"In a world gone dry... one man brought a hose.",
	"Now with 100% more hose.",
	"Please register your hours before hosing.",
	"The Council of Hose has convened.",
	"Rated H for Hose.",
	"This summer: stay hydrated.",
]

var _title: Label
var _t: float = 0.0


func _ready() -> void:
	add_child(MenuBackdrop.new())
	AudioManager.play_music(load("res://assets/audio/music/wasteland_loop.wav"))

	add_child(MenuHelpers.centered_label("THE CINEMATIC UNIVERSE OF JON HOSE PRESENTS", 46, 8, UiTheme.WATER_LIGHT))
	var shadow := MenuHelpers.centered_label("HOSE SURVIVORS", 66, 40, UiTheme.INK, true)
	shadow.position += Vector2(3, 3)
	add_child(shadow)
	_title = MenuHelpers.centered_label("HOSE SURVIVORS", 66, 40, UiTheme.BRASS, true)
	add_child(_title)
	add_child(MenuHelpers.centered_label(TAGLINES.pick_random(), 118, 8, UiTheme.TEXT))

	var jon := Sprite2D.new()
	jon.texture = JON
	jon.hframes = 6
	jon.scale = Vector2(5, 5)
	jon.position = Vector2(140, 240)
	add_child(jon)
	var nozzle := Sprite2D.new()
	nozzle.texture = NOZZLE
	nozzle.scale = Vector2(5, 5)
	nozzle.position = Vector2(185, 252)
	add_child(nozzle)

	var box := VBoxContainer.new()
	box.position = Vector2(245, 170)
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var start := MenuHelpers.button("START RUN", Router.goto_character_select)
	box.add_child(start)
	if not OS.has_feature("web"):  # a browser tab can't be closed from the game
		box.add_child(MenuHelpers.button("QUIT", func() -> void: get_tree().quit()))
	start.grab_focus.call_deferred()

	var stats := PanelContainer.new()
	stats.position = Vector2(440, 170)
	add_child(stats)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	stats.add_child(v)
	v.add_child(UiTheme.label("SERVICE RECORD", 8, UiTheme.BRASS, true))
	v.add_child(UiTheme.label("HOSE COINS   %d" % SaveManager.get_coins(), 8, UiTheme.BRASS))
	v.add_child(UiTheme.label("RUNS   %d   WINS   %d" % [SaveManager.data["runs"], SaveManager.data["wins"]]))
	v.add_child(UiTheme.label("ENEMIES HOSED   %d" % SaveManager.data["total_kills"]))
	v.add_child(UiTheme.label("BEST TIME   %s" % RunState.format_time(SaveManager.data["best_time"])))

	var hint := MenuHelpers.centered_label("WASD / ARROWS / LEFT STICK: MOVE     ESC / START: PAUSE", 336, 8, UiTheme.TEXT_DIM)
	add_child(hint)
	var version := UiTheme.label("v%s  PLACEHOLDER ART" % ProjectSettings.get_setting("application/config/version"), 8, UiTheme.TEXT_DIM)
	version.position = Vector2(6, 346)
	add_child(version)


func _process(delta: float) -> void:
	_t += delta
	_title.position.y = 66.0 + roundf(sin(_t * 2.0) * 2.0)
