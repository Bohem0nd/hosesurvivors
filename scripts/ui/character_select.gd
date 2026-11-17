extends Control
## Character roster. Everything shown comes from CharacterData resources;
## characters that are not implemented or not unlocked appear as silhouettes.

const ROSTER: Array[String] = [
	"res://resources/characters/jon_hose.tres",
	"res://resources/characters/ass_man.tres",
	"res://resources/characters/the_crackler.tres",
	"res://resources/characters/quakewalker.tres",
	"res://resources/characters/the_memeweaver.tres",
	"res://resources/characters/the_shopkeeper.tres",
]
const SILHOUETTE := preload("res://assets/sprites/characters/locked_silhouette.png")
const CARD := Vector2(92, 104)

var _detail_name: Label
var _detail_title: Label
var _detail_body: Label
var _start: Button
var _selected: CharacterData


func _ready() -> void:
	add_child(MenuBackdrop.new())
	var frame := MenuHelpers.frame()
	add_child(frame)
	frame.add_child(MenuHelpers.centered_label("CHOOSE YOUR HERO", 14, 24, UiTheme.BRASS, true))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(20, 52)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	frame.add_child(grid)

	var panel := PanelContainer.new()
	panel.position = Vector2(326, 52)
	panel.custom_minimum_size = Vector2(294, 214)
	frame.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	_detail_name = UiTheme.label("", 16, UiTheme.BRASS, true)
	v.add_child(_detail_name)
	_detail_title = UiTheme.label("", 8, UiTheme.WATER_LIGHT)
	v.add_child(_detail_title)
	_detail_body = UiTheme.label("", 8, UiTheme.TEXT)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.custom_minimum_size = Vector2(280, 0)
	v.add_child(_detail_body)

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(326, 286)
	buttons.add_theme_constant_override("separation", 8)
	frame.add_child(buttons)
	_start = MenuHelpers.button("BEGIN HOSING", func() -> void: Router.start_run(_selected), 160)
	buttons.add_child(_start)
	buttons.add_child(MenuHelpers.button("BACK", Router.goto_menu, 80))

	var first: Button = null
	for path in ROSTER:
		var character: CharacterData = load(path)
		var card := _make_card(character)
		grid.add_child(card)
		if first == null:
			first = card
	first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		Router.goto_menu()


func _playable(character: CharacterData) -> bool:
	return character.implemented and SaveManager.is_unlocked(character)


func _make_card(character: CharacterData) -> Button:
	var playable := _playable(character)
	var card := Button.new()
	card.custom_minimum_size = CARD
	card.focus_entered.connect(_show.bind(character))
	card.mouse_entered.connect(card.grab_focus)
	card.pressed.connect(func() -> void:
		# On touch the tap that selects a hero would also start the run before the
		# player could read about them; there, BEGIN HOSING starts it instead.
		if _playable(character) and not Device.touch_mode:
			AudioManager.play(&"ui_select")
			Router.start_run(character))

	var sprite := TextureRect.new()
	if playable and character.sprite_sheet != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = character.sprite_sheet
		var fw := character.sprite_sheet.get_width() / character.frame_count
		atlas.region = Rect2(0, 0, fw, character.sprite_sheet.get_height())
		sprite.texture = atlas
	else:
		sprite.texture = SILHOUETTE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(48, 72)
	sprite.position = Vector2(CARD.x * 0.5 - 24, 6)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sprite)

	var name_label := UiTheme.label(character.display_name.to_upper() if playable else "LOCKED", 8,
			UiTheme.TEXT if playable else UiTheme.TEXT_DIM)
	name_label.position = Vector2(0, 86)
	name_label.size = Vector2(CARD.x, 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)
	return card


func _show(character: CharacterData) -> void:
	_selected = character
	var playable := _playable(character)
	_detail_name.text = character.display_name.to_upper()
	_detail_title.text = character.title.to_upper()
	var lines: Array[String] = [character.description, ""]
	if character.starting_weapon != null:
		lines.append("WEAPON: %s" % character.starting_weapon.display_name)
		lines.append(character.starting_weapon.description)
		lines.append("")
	elif character.weapon_preview != "":
		lines.append("WEAPON: %s" % character.weapon_preview)
		lines.append("")
	lines.append("PASSIVE: %s" % character.passive_name)
	lines.append(character.passive_description)
	lines.append("")
	lines.append("HEALTH %d    SPEED %d    DAMAGE x%.1f" % [character.max_health, character.move_speed, character.damage_multiplier])
	if not playable:
		lines.append("")
		lines.append("LOCKED - %s" % character.unlock_hint)
	_detail_body.text = "\n".join(lines)
	_start.disabled = not playable
