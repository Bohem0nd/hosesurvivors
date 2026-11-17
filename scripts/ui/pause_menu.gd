class_name PauseMenu
extends CanvasLayer
## ESC / Start / on-screen pause menu. Also opens on its own when the app loses focus.

const QUIPS := [
	"This meeting could have been an email.",
	"Jon Hose is hydrating. Please hold.",
	"Your timesheet remains unregistered.",
	"The Council of Hose is in recess.",
]

## Set by Game: returns false while another modal (level-up, end screen) is up.
var can_pause: Callable
var _root: Control
var _quip: Label
var _resume: Button


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.theme  # themes do not propagate through CanvasLayers
	add_child(_root)
	_root.add_child(MenuHelpers.dim())
	var frame := MenuHelpers.frame()
	_root.add_child(frame)
	frame.add_child(MenuHelpers.centered_label("PAUSED", 90, 24, UiTheme.BRASS, true))
	_quip = MenuHelpers.centered_label("", 124, 8, UiTheme.TEXT_DIM)
	frame.add_child(_quip)
	var box := VBoxContainer.new()
	box.position = Vector2(245, 150)
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)
	_resume = MenuHelpers.button("RESUME", close)
	box.add_child(_resume)
	box.add_child(MenuHelpers.button("RESTART RUN", func() -> void: Router.start_run(RunState.character, RunState.stage)))
	box.add_child(MenuHelpers.button("QUIT TO MENU", Router.goto_menu))
	Device.orientation_blocked.connect(request_open)


## Pause if allowed: the HUD pause button, the app losing focus, a phone turned to portrait.
func request_open() -> void:
	if not visible and can_pause.is_valid() and can_pause.call():
		open()


func _notification(what: int) -> void:
	# Switching apps or tabs on a phone shouldn't cost the run.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		request_open()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if visible:
		close()
	else:
		request_open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_quip.text = QUIPS.pick_random()
	visible = true
	get_tree().paused = true
	_resume.grab_focus.call_deferred()


func close() -> void:
	visible = false
	get_tree().paused = false
