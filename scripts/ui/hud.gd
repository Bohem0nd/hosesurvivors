class_name Hud
extends CanvasLayer
## In-run HUD: XP bar, health, timer, kills, coins, build icons, boss bar and
## the cinematic announcement banner.

const W := 640.0
const H := 360.0

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

	_xp_bar = PixelBar.new()
	_xp_bar.position = Vector2(0, 0)
	_xp_bar.size = Vector2(W, 7)
	_xp_bar.fill_color = UiTheme.WATER
	_xp_bar.ratio = 0.0
	root.add_child(_xp_bar)
	_level_label = UiTheme.label("LV 1", 8, UiTheme.BRASS, true)
	_level_label.position = Vector2(W - 60, 10)
	_level_label.size = Vector2(56, 10)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_level_label)

	_hp_bar = PixelBar.new()
	_hp_bar.position = Vector2(6, 12)
	_hp_bar.size = Vector2(104, 10)
	_hp_bar.fill_color = UiTheme.DANGER
	_hp_bar.show_ghost = true
	root.add_child(_hp_bar)
	_icons = HBoxContainer.new()
	_icons.position = Vector2(6, 25)
	_icons.add_theme_constant_override("separation", 2)
	root.add_child(_icons)

	_passive_label = UiTheme.label("", 8, UiTheme.WATER_LIGHT)
	_passive_label.position = Vector2(6, 52)
	root.add_child(_passive_label)

	_timer_label = UiTheme.label("00:00", 16, UiTheme.TEXT, true)
	_timer_label.position = Vector2(W * 0.5 - 60, 11)
	_timer_label.size = Vector2(120, 18)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_timer_label)

	_kills_label = UiTheme.label("KILLS 0")
	_kills_label.position = Vector2(W - 126, 22)
	_kills_label.size = Vector2(122, 10)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_kills_label)
	var coin := TextureRect.new()
	coin.texture = preload("res://assets/sprites/pickups/coin.png")
	coin.position = Vector2(W - 13, 34)
	root.add_child(coin)
	_coins_label = UiTheme.label("0", 8, UiTheme.BRASS)
	_coins_label.position = Vector2(W - 126, 33)
	_coins_label.size = Vector2(110, 10)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_coins_label)

	# Boss bar
	_boss_box = Control.new()
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_box)
	_boss_name = UiTheme.label("", 8, UiTheme.DANGER, true)
	_boss_name.position = Vector2(W * 0.5 - 180, H - 34)
	_boss_name.size = Vector2(360, 10)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = PixelBar.new()
	_boss_bar.position = Vector2(W * 0.5 - 180, H - 22)
	_boss_bar.size = Vector2(360, 10)
	_boss_bar.fill_color = Color("c9612e")
	_boss_bar.show_ghost = true
	_boss_box.add_child(_boss_bar)

	# Announcement banner + letterbox bars
	for i in 2:
		var bar := ColorRect.new()
		bar.color = UiTheme.INK
		bar.size = Vector2(W, 28)
		bar.position = Vector2(0, -28 if i == 0 else H)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
		_bars.append(bar)
	_banner = Control.new()
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_banner)
	var strip := ColorRect.new()
	strip.color = Color(UiTheme.INK, 0.72)
	strip.position = Vector2(0, 76)
	strip.size = Vector2(W, 44)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(strip)
	_banner_title = UiTheme.label("", 16, UiTheme.BRASS, true)
	_banner_title.position = Vector2(0, 82)
	_banner_title.size = Vector2(W, 18)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner_sub = UiTheme.label("", 8, UiTheme.TEXT)
	_banner_sub.position = Vector2(0, 104)
	_banner_sub.size = Vector2(W, 10)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_sub)


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
		bars.tween_property(_bars[0], "position:y", 0.0, 0.4)
		bars.tween_property(_bars[1], "position:y", H - 28.0, 0.4)
		bars.chain().tween_interval(3.0)
		bars.chain().tween_property(_bars[0], "position:y", -28.0, 0.5)
		bars.parallel().tween_property(_bars[1], "position:y", H, 0.5)
