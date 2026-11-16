extends Node
## Builds the game-wide UI theme in code (retro arcade x cinematic superhero)
## and exposes palette + font helpers for UI scripts.

const NAVY := Color("12162b")
const NAVY_LIGHT := Color("1f2748")
const BRASS := Color("d6a840")
const BRASS_DARK := Color("7a5a1c")
const WATER := Color("54acff")
const WATER_LIGHT := Color("c8eaff")
const TEXT := Color("f2ead8")
const TEXT_DIM := Color("9aa0b8")
const DANGER := Color("e2483c")
const GOOD := Color("58d68a")
const INK := Color("0a0810")

var font_title: FontFile
var font_body: FontFile
var theme: Theme


func _ready() -> void:
	font_title = _load_font("res://assets/fonts/PressStart2P-Regular.ttf")
	font_body = _load_font("res://assets/fonts/Silkscreen-Regular.ttf")
	theme = _build()
	get_tree().root.theme = theme


func _load_font(path: String) -> FontFile:
	var font: FontFile = load(path)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.hinting = TextServer.HINTING_NONE
	return font


static func box(bg: Color, border: Color, border_width: int = 1, margin: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = false
	return sb


func _build() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 8

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", INK)
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)

	t.set_stylebox("panel", "PanelContainer", box(Color(NAVY, 0.94), BRASS, 1, 6))
	t.set_stylebox("panel", "Panel", box(Color(NAVY, 0.94), BRASS, 1, 6))

	t.set_font("font", "Button", font_title)
	t.set_font_size("font_size", "Button", 8)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", BRASS)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)
	t.set_stylebox("normal", "Button", box(NAVY_LIGHT, BRASS_DARK, 1, 6))
	t.set_stylebox("hover", "Button", box(Color("2a3a78"), BRASS, 1, 6))
	t.set_stylebox("focus", "Button", box(Color("2a3a78"), WATER, 2, 5))
	t.set_stylebox("pressed", "Button", box(NAVY, BRASS, 1, 6))
	t.set_stylebox("disabled", "Button", box(Color(NAVY, 0.7), Color("3a3a4a"), 1, 6))

	t.set_stylebox("background", "ProgressBar", box(INK, INK, 1, 0))
	t.set_stylebox("fill", "ProgressBar", box(WATER, WATER, 0, 0))
	return t


## Label factory so every screen gets consistent pixel-perfect text.
func label(text: String, size: int = 8, color: Color = TEXT, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_title if title else font_body)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
