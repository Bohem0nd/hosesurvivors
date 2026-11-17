class_name Hud
extends CanvasLayer
## In-run HUD: XP bar, health, timer, kills, coins, build icons, boss bar and
## the cinematic announcement banner. Elements are laid out in 640x360 design
## coordinates and pinned to the matching screen edge, so the HUD hugs the corners
## on wider or taller screens. On touch screens it adds a pause button.

signal pause_pressed

const W := 640.0
const H := 360.0
const PAUSE_BUTTON := Vector2(28, 28)

var _ctx: GameContext
var _upgrades: UpgradeSystem

var _xp_bar: PixelBar
var _level_label: Label
var _hp_bar: PixelBar
var _passive_label: Label
var _timer_label: Label
var _kills_label: Label
var _coins_label: Label
var _icons: HBoxContainer
var _boss_box: Control
var _boss_bar: PixelBar
var _boss_name: Label
var _boss: Enemy
var _banner: Control
var _banner_title: Label
var _banner_sub: Label
var _bars: Array[ColorRect] = []
var _right_column: Control
var _pause_button: Button
var _banner_tween: Tween
var _last_second: int = -1
var _last_kills: int = -1


func setup(ctx: GameContext, upgrades: UpgradeSystem) -> void:
	_ctx = ctx
	_upgrades = upgrades
	layer = 2
	_build()
	ctx.player.health.changed.connect(_on_health_changed)
	ctx.player.weapons.weapons_changed.connect(_refresh_icons)
	Events.xp_changed.connect(_on_xp_changed)
	Events.level_up.connect(func(_l: int) -> void: _level_label.text = "LV %d" % RunState.level)
	Events.coins_changed.connect(func(c: int) -> void: _coins_label.text = "%d" % c)
	Events.upgrade_applied.connect(func(_o: UpgradeOffer) -> void: _refresh_icons())
	Events.boss_spawned.connect(_on_boss_spawned)
	Events.boss_defeated.connect(func(_d: EnemyData) -> void: _boss_box.visible = false)
	Events.announcement.connect(_announce)
	_on_health_changed(ctx.player.health.health, ctx.player.health.max_health)
	_refresh_icons()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.theme  # themes do not propagate through CanvasLayers
	add_child(root)
	var top_left := _pin(root, Vector2(0.0, 0.0))
	var top := _pin(root, Vector2(0.5, 0.0))
	var top_right := _pin(root, Vector2(1.0, 0.0))
	var bottom := _pin(root, Vector2(0.5, 1.0))

	_xp_bar = PixelBar.new()
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 7
	_xp_bar.fill_color = UiTheme.WATER
	_xp_bar.ratio = 0.0
	root.add_child(_xp_bar)

	# Level, kills and coins share a column that steps aside for the pause button.
	_right_column = Control.new()
	_right_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(top_right, _right_column, Vector2(0, 0))
	_level_label = UiTheme.label("LV 1", 8, UiTheme.BRASS, true)
	_level_label.size = Vector2(56, 10)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_right_column, _level_label, Vector2(W - 60, 10))

	_hp_bar = PixelBar.new()
	_hp_bar.position = Vector2(6, 12)
	_hp_bar.size = Vector2(104, 10)
	_hp_bar.fill_color = UiTheme.DANGER
	_hp_bar.show_ghost = true
	top_left.add_child(_hp_bar)
	_icons = HBoxContainer.new()
	_icons.position = Vector2(6, 25)
	_icons.add_theme_constant_override("separation", 2)
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(_icons)

	_passive_label = UiTheme.label("", 8, UiTheme.WATER_LIGHT)
	_passive_label.position = Vector2(6, 52)
	top_left.add_child(_passive_label)

	_timer_label = UiTheme.label("00:00", 16, UiTheme.TEXT, true)
	_timer_label.size = Vector2(120, 18)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(top, _timer_label, Vector2(W * 0.5 - 60, 11))

	_kills_label = UiTheme.label("KILLS 0")
	_kills_label.size = Vector2(122, 10)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_right_column, _kills_label, Vector2(W - 126, 22))
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/sprites/pickups/coin.png")
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_right_column, coin, Vector2(W - 13, 34))
	_coins_label = UiTheme.label("0", 8, UiTheme.BRASS)
	_coins_label.size = Vector2(110, 10)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_right_column, _coins_label, Vector2(W - 126, 33))

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.size = PAUSE_BUTTON
	_pause_button.add_theme_color_override("font_color", UiTheme.BRASS)
	_pause_button.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.NAVY, 0.7), UiTheme.BRASS_DARK, 1, 0))
	_pause_button.add_theme_stylebox_override("hover", UiTheme.box(Color(UiTheme.NAVY, 0.7), UiTheme.BRASS_DARK, 1, 0))
	_pause_button.add_theme_stylebox_override("pressed", UiTheme.box(UiTheme.NAVY_LIGHT, UiTheme.BRASS, 1, 0))
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_place(top_right, _pause_button, Vector2(W - PAUSE_BUTTON.x - 4, 10))
	_set_touch_layout(Device.touch_mode)
	Device.touch_mode_changed.connect(_set_touch_layout)

	# Boss bar
	_boss_box = Control.new()
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_boss_box)
	_boss_name = UiTheme.label("", 8, UiTheme.DANGER, true)
	_boss_name.size = Vector2(360, 10)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_boss_box, _boss_name, Vector2(W * 0.5 - 180, H - 34), Vector2(0.5, 1.0))
	_boss_bar = PixelBar.new()
	_boss_bar.size = Vector2(360, 10)
	_boss_bar.fill_color = Color("c9612e")
	_boss_bar.show_ghost = true
	_place(_boss_box, _boss_bar, Vector2(W * 0.5 - 180, H - 22), Vector2(0.5, 1.0))

	# Announcement banner + letterbox bars (these span the whole screen width)
	for i in 2:
		var bar := ColorRect.new()
		bar.color = UiTheme.INK
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if i == 0 else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -28.0 if i == 0 else 0.0
		bar.offset_bottom = 0.0 if i == 0 else 28.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
		_bars.append(bar)
	_banner = Control.new()
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_banner)
	var strip := ColorRect.new()
	strip.color = Color(UiTheme.INK, 0.72)
	strip.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	strip.offset_top = 76 - H * 0.5
	strip.offset_bottom = strip.offset_top + 44
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(strip)
	var banner_frame := _pin(_banner, Vector2(0.5, 0.5))
	_banner_title = UiTheme.label("", 16, UiTheme.BRASS, true)
	_banner_title.size = Vector2(W, 18)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(banner_frame, _banner_title, Vector2(0, 82), Vector2(0.5, 0.5))
	_banner_sub = UiTheme.label("", 8, UiTheme.TEXT)
	_banner_sub.size = Vector2(W, 10)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(banner_frame, _banner_sub, Vector2(0, 104), Vector2(0.5, 0.5))


## A zero-size anchor point on the screen (0,0 = top-left, 1,1 = bottom-right).
func _pin(parent: Control, anchor: Vector2) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	parent.add_child(c)
	return c


## Adds `node` under an anchor pin at its 640x360 design position.
func _place(pin: Control, node: Control, design_pos: Vector2, anchor: Vector2 = Vector2(-1, -1)) -> void:
	if anchor.x < 0.0:
		anchor = Vector2(pin.anchor_left, pin.anchor_top)
	node.position = design_pos - anchor * Vector2(W, H)
	pin.add_child(node)


func _set_touch_layout(touch: bool) -> void:
	_pause_button.visible = touch
	_right_column.position.x = -W - (PAUSE_BUTTON.x + 6.0 if touch else 0.0)


func _process(_delta: float) -> void:
	var second := int(RunState.time)
	if second != _last_second:
		_last_second = second
		_timer_label.text = RunState.format_time(RunState.time)
		if _ctx.player.passive != null:
			_passive_label.text = _ctx.player.passive.get_status_text()
	if RunState.kills != _last_kills:
		_last_kills = RunState.kills
		_kills_label.text = "KILLS %d" % RunState.kills
	if _boss != null and _boss_box.visible:
		_boss_bar.ratio = _boss.hp / _boss.max_hp if _boss.alive else 0.0


func _on_health_changed(health: float, max_health: float) -> void:
	_hp_bar.ratio = health / max_health
	_hp_bar.text = "%d/%d" % [ceili(health), roundi(max_health)]


func _on_xp_changed(xp: int, required: int) -> void:
	_xp_bar.ratio = float(xp) / float(required)


func _on_boss_spawned(enemy: Enemy) -> void:
	_boss = enemy
	_boss_name.text = enemy.data.display_name.to_upper()
	_boss_bar.ratio = 1.0
	_boss_box.visible = true
	_timer_label.add_theme_color_override("font_color", UiTheme.DANGER)


func _refresh_icons() -> void:
	for child in _icons.get_children():
		child.queue_free()
	for weapon in _ctx.player.weapons.weapons:
		_icons.add_child(_icon(weapon.data.icon, weapon.level, UiTheme.BRASS))
	for upgrade in _upgrades.pool.passives:
		var lvl := _upgrades.get_passive_level(upgrade.id)
		if lvl > 0:
			_icons.add_child(_icon(upgrade.icon, lvl, UiTheme.TEXT_DIM))


func _icon(texture: Texture2D, level: int, border: Color) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(18, 24)
	var frame := ColorRect.new()
	frame.color = border
	frame.size = Vector2(18, 18)
	box.add_child(frame)
	var tex := TextureRect.new()
	tex.texture = texture
	tex.position = Vector2(1, 1)
	box.add_child(tex)
	var lbl := UiTheme.label(str(level), 8, UiTheme.TEXT)
	lbl.position = Vector2(0, 17)
	lbl.size = Vector2(18, 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	return box


func _announce(title: String, subtitle: String, is_boss: bool) -> void:
	_banner_title.text = title
	_banner_sub.text = subtitle
	_banner_title.add_theme_color_override("font_color", UiTheme.DANGER if is_boss else UiTheme.BRASS)
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_interval(3.2 if is_boss else 2.2)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.5)
	if is_boss:
		var bars := create_tween().set_parallel(true)
		bars.tween_property(_bars[0], "offset_top", 0.0, 0.4)
		bars.tween_property(_bars[0], "offset_bottom", 28.0, 0.4)
		bars.tween_property(_bars[1], "offset_top", -28.0, 0.4)
		bars.tween_property(_bars[1], "offset_bottom", 0.0, 0.4)
		bars.chain().tween_interval(3.0)
		bars.chain().tween_property(_bars[0], "offset_top", -28.0, 0.5)
		bars.parallel().tween_property(_bars[0], "offset_bottom", 0.0, 0.5)
		bars.parallel().tween_property(_bars[1], "offset_top", 0.0, 0.5)
		bars.parallel().tween_property(_bars[1], "offset_bottom", 28.0, 0.5)
