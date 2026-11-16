class_name LevelUpScreen
extends CanvasLayer
## Three-card upgrade picker. Runs while the tree is paused.

signal offer_chosen(offer: UpgradeOffer)

const CARD_SIZE := Vector2(172, 150)
const INPUT_LOCK := 0.35

var _root: Control
var _title: Label
var _subtitle: Label
var _cards: HBoxContainer
var _open_time: int = 0
var current_offers: Array[UpgradeOffer] = []


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.theme  # themes do not propagate through CanvasLayers
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_title = UiTheme.label("LEVEL UP!", 24, UiTheme.BRASS, true)
	_title.position = Vector2(0, 50)
	_title.size = Vector2(640, 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_title)
	_subtitle = UiTheme.label("", 8, UiTheme.WATER_LIGHT)
	_subtitle.position = Vector2(0, 82)
	_subtitle.size = Vector2(640, 10)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_subtitle)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.position = Vector2(0, 110)
	_cards.size = Vector2(640, CARD_SIZE.y)
	_root.add_child(_cards)


func open(offers: Array[UpgradeOffer], title: String, subtitle: String) -> void:
	current_offers = offers
	_title.text = title
	_subtitle.text = subtitle
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var first: Button = null
	for offer in offers:
		var card := _make_card(offer)
		_cards.add_child(card)
		if first == null:
			first = card
	visible = true
	_open_time = Time.get_ticks_msec()
	if first != null:
		first.grab_focus.call_deferred()
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.15)


func _make_card(offer: UpgradeOffer) -> Button:
	var special := offer.is_special()
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	var border := UiTheme.BRASS if special else UiTheme.BRASS_DARK
	card.add_theme_stylebox_override("normal", UiTheme.box(Color("3a2410") if special else UiTheme.NAVY, border, 1, 0))
	card.add_theme_stylebox_override("hover", UiTheme.box(Color("2a3a78"), UiTheme.WATER, 2, 0))
	card.add_theme_stylebox_override("focus", UiTheme.box(Color("2a3a78"), UiTheme.WATER, 2, 0))
	card.add_theme_stylebox_override("pressed", UiTheme.box(UiTheme.NAVY_LIGHT, UiTheme.BRASS, 2, 0))
	card.pressed.connect(_choose.bind(offer))
	card.focus_entered.connect(func() -> void: AudioManager.play(&"ui_move", -8.0, 0.0))
	card.mouse_entered.connect(card.grab_focus)

	var icon := TextureRect.new()
	icon.texture = offer.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.position = Vector2(CARD_SIZE.x * 0.5 - 16, 12)
	icon.size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)

	var tag := UiTheme.label(offer.level_text, 8, UiTheme.BRASS if special else UiTheme.WATER)
	tag.position = Vector2(0, 50)
	tag.size = Vector2(CARD_SIZE.x, 10)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(tag)

	var title := UiTheme.label(offer.title.to_upper(), 8, UiTheme.TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(title)
	title.position = Vector2(6, 64)
	title.size = Vector2(CARD_SIZE.x - 12, 22)

	var desc := UiTheme.label(offer.description, 8, UiTheme.TEXT_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(desc)
	# Size must be set after autowrap is on, or the label keeps its one-line width.
	desc.position = Vector2(8, 92)
	desc.size = Vector2(CARD_SIZE.x - 16, 54)
	return card


func _choose(offer: UpgradeOffer) -> void:
	# Ignore presses in the first moments so a mashed button can't pick blindly.
	if not visible or Time.get_ticks_msec() - _open_time < int(INPUT_LOCK * 1000.0):
		return
	visible = false
	AudioManager.play(&"ui_select")
	offer_chosen.emit(offer)
