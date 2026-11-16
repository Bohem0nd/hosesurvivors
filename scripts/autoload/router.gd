extends CanvasLayer
## Scene switching with a quick fade.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT := "res://scenes/ui/character_select.tscn"
const GAME := "res://scenes/game.tscn"
const DEFAULT_STAGE := "res://resources/stages/dry_wastelands.tres"

var pending_character: CharacterData
var pending_stage: StageData

var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.03, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func goto_menu() -> void:
	_change(MAIN_MENU)


func goto_character_select() -> void:
	_change(CHARACTER_SELECT)


func start_run(character: CharacterData, stage: StageData = null) -> void:
	pending_character = character
	pending_stage = stage if stage != null else load(DEFAULT_STAGE)
	_change(GAME)


func _change(path: String) -> void:
	if _busy:
		return
	_busy = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.18)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.22)
	await tween.finished
	_busy = false
