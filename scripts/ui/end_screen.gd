class_name EndScreen
extends CanvasLayer
## Victory / defeat summary.

const DEFEAT_QUIPS := [
	"The Great Drying claims another.",
	"Cause of death: insufficient hydration.",
	"HR has been notified.",
	"Your hours remain unregistered. Forever.",
	"The hose went limp.",
]
const VICTORY_QUIPS := [
	"The Hoseverse is moist once more.",
	"Jon Hose logs 10 minutes of overtime.",
	"The Council of Hose approves. Unanimously.",
]


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS


func open(victory: bool, coins_before: int) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.theme  # themes do not propagate through CanvasLayers
	add_child(root)
	root.add_child(MenuHelpers.dim(0.82))
	var frame := MenuHelpers.frame()
	root.add_child(frame)
	var color := UiTheme.BRASS if victory else UiTheme.DANGER
	frame.add_child(MenuHelpers.centered_label("THE HOSE PREVAILS" if victory else "YOU GOT HOSED", 48, 24, color, true))
	var quips := VICTORY_QUIPS if victory else DEFEAT_QUIPS
	frame.add_child(MenuHelpers.centered_label(quips.pick_random(), 82, 8, UiTheme.TEXT_DIM))

	var panel := PanelContainer.new()
	panel.position = Vector2(200, 108)
	panel.custom_minimum_size = Vector2(240, 0)
	frame.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 5)
	panel.add_child(grid)
	_row(grid, "HERO", RunState.character.display_name.to_upper())
	_row(grid, "TIME SURVIVED", RunState.format_time(RunState.time))
	_row(grid, "ENEMIES HOSED", str(RunState.kills))
	_row(grid, "LEVEL REACHED", str(RunState.level))
	_row(grid, "HOSE COINS EARNED", "+%d" % RunState.coins, UiTheme.BRASS)
	_row(grid, "HOSE COINS BANKED", str(coins_before + RunState.coins), UiTheme.BRASS)

	var box := HBoxContainer.new()
	box.position = Vector2(0, 232)
	box.size = Vector2(640, 20)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)
	var retry := MenuHelpers.button("HOSE AGAIN", func() -> void: Router.start_run(RunState.character, RunState.stage))
	box.add_child(retry)
	box.add_child(MenuHelpers.button("MAIN MENU", Router.goto_menu))
	retry.grab_focus.call_deferred()

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.4)


func _row(grid: GridContainer, key: String, value: String, color: Color = UiTheme.TEXT) -> void:
	var k := UiTheme.label(key, 8, UiTheme.TEXT_DIM)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(k)
	var v := UiTheme.label(value, 8, color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(v)
