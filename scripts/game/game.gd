class_name Game
extends Node2D
## Root of a run. Builds the world and its systems, wires them together through
## a GameContext, and handles the run flow: level-ups, pause, victory, defeat.

const DEFAULT_CHARACTER := "res://resources/characters/jon_hose.tres"
const DEFAULT_STAGE := "res://resources/stages/dry_wastelands.tres"
const UPGRADE_POOL := "res://resources/upgrades/upgrade_pool.tres"
const VIGNETTE := preload("res://assets/sprites/effects/vignette.png")

var ctx := GameContext.new()
var upgrades: UpgradeSystem
var director: SpawnDirector
var hud: Hud
var level_up_screen: LevelUpScreen
var pause_menu: PauseMenu

var _pending_level_ups: int = 0
var _pending_crates: int = 0
var _choosing: bool = false
var _ending: bool = false


func _ready() -> void:
	var character: CharacterData = Router.pending_character
	if character == null:
		character = load(DEFAULT_CHARACTER)
	var stage: StageData = Router.pending_stage
	if stage == null:
		stage = load(DEFAULT_STAGE)
	_build_world(character, stage)
	_build_ui()

	Events.level_up.connect(_on_level_up)
	Events.crate_collected.connect(_on_crate_collected)
	# Deferred: these fire from inside the enemy/projectile update loops, and the
	# handlers mutate those same collections.
	Events.player_died.connect(_on_player_died, CONNECT_DEFERRED)
	Events.boss_defeated.connect(_on_boss_defeated, CONNECT_DEFERRED)
	Events.weapon_evolved.connect(_on_weapon_evolved)

	RunState.start(character, stage)
	AudioManager.play_music(stage.music)
	Events.announcement.emit(stage.display_name.to_upper(), "Survive. Hydrate. Prevail.", false)


func _build_world(character: CharacterData, stage: StageData) -> void:
	ctx.stage = stage

	ctx.camera = GameCamera.new()
	add_child(ctx.camera)

	ctx.rings = RingField.new()
	ctx.rings.z_index = -5
	add_child(ctx.rings)

	ctx.hazards = Node2D.new()
	ctx.hazards.z_index = -4
	add_child(ctx.hazards)

	ctx.pickups = PickupManager.new()
	ctx.pickups.z_index = -3
	add_child(ctx.pickups)

	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)

	ctx.player = Player.new()
	entities.add_child(ctx.player)
	ctx.enemies = EnemyManager.new()
	entities.add_child(ctx.enemies)

	ctx.projectiles = ProjectileManager.new()
	ctx.projectiles.z_index = 2
	add_child(ctx.projectiles)
	ctx.particles = ParticleField.new()
	ctx.particles.z_index = 3
	add_child(ctx.particles)
	ctx.numbers = DamageNumbers.new()
	ctx.numbers.z_index = 4
	add_child(ctx.numbers)

	ctx.enemies.setup(ctx)
	ctx.projectiles.setup(ctx)
	ctx.pickups.setup(ctx)
	ctx.player.setup(character, ctx)
	ctx.camera.target = ctx.player
	ctx.camera.make_current()

	var ground := Ground.new()
	ground.z_index = -10
	add_child(ground)
	ground.setup(stage, ctx.camera, entities)

	director = SpawnDirector.new()
	add_child(director)
	director.setup(ctx, stage)

	upgrades = UpgradeSystem.new(load(UPGRADE_POOL), ctx.player)


func _build_ui() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	add_child(overlay)
	var vignette := TextureRect.new()
	vignette.texture = VIGNETTE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.add_child(vignette)

	add_child(TouchControls.new())

	hud = Hud.new()
	add_child(hud)
	hud.setup(ctx, upgrades)

	level_up_screen = LevelUpScreen.new()
	add_child(level_up_screen)
	level_up_screen.offer_chosen.connect(_on_offer_chosen)

	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.can_pause = func() -> bool: return RunState.active and not _choosing and not _ending
	hud.pause_pressed.connect(pause_menu.request_open)


func _process(delta: float) -> void:
	if RunState.active and ctx.player.alive and not RunState.boss_phase:
		RunState.time = minf(RunState.time + delta, ctx.stage.duration)


# --- Level-ups and supply crates -------------------------------------------

func _on_level_up(_level: int) -> void:
	_pending_level_ups += 1
	_show_next_choice.call_deferred()


func _on_crate_collected() -> void:
	_pending_crates += 1
	_show_next_choice.call_deferred()


func _show_next_choice() -> void:
	if _choosing or _ending or not ctx.player.alive:
		return
	var from_crate := false
	if _pending_level_ups > 0:
		_pending_level_ups -= 1
	elif _pending_crates > 0:
		_pending_crates -= 1
		from_crate = true
	else:
		return
	var offers := upgrades.roll_offers(3)
	if offers.is_empty():
		_show_next_choice()
		return
	_choosing = true
	get_tree().paused = true
	AudioManager.play(&"level_up")
	level_up_screen.open(offers, "SUPPLY DROP!" if from_crate else "LEVEL UP!",
			"Courtesy of the Shopkeeper." if from_crate else "Level %d - choose your upgrade" % RunState.level)


func _on_offer_chosen(offer: UpgradeOffer) -> void:
	upgrades.apply(offer)
	_choosing = false
	if _pending_level_ups > 0 or _pending_crates > 0:
		_show_next_choice()
	else:
		get_tree().paused = false


func _on_weapon_evolved(weapon: WeaponData) -> void:
	AudioManager.play(&"evolution")
	ctx.camera.shake(6.0)
	ctx.rings.ring(ctx.player.position, 8.0, 120.0, 0.6, Color(1.0, 0.9, 0.5), 3.0)
	ctx.particles.burst(ctx.player.position, 40, Color(1.0, 0.85, 0.4), 40.0, 200.0, 0.8, 2.0)
	Events.announcement.emit(weapon.display_name.to_upper(), "WEAPON EVOLVED", false)


# --- Run end ----------------------------------------------------------------

func _on_player_died() -> void:
	if _ending:
		return
	_ending = true
	AudioManager.stop_music()
	AudioManager.play(&"defeat")
	await get_tree().create_timer(1.4, false).timeout
	_finish(false)


func _on_boss_defeated(_data: EnemyData) -> void:
	if _ending or not ctx.player.alive:
		return
	_ending = true
	ctx.player.invulnerable = true
	ctx.projectiles.clear_team(ProjectileManager.Team.ENEMY)
	for hazard in ctx.hazards.get_children():
		hazard.queue_free()
	ctx.enemies.clear_normals()
	ctx.pickups.attract_all()
	AudioManager.stop_music()
	AudioManager.play(&"victory")
	Events.announcement.emit("THE DRYING IS OVER", "Moisture has been restored to the Hoseverse.", false)
	await get_tree().create_timer(2.6, false).timeout
	_finish(true)


func _finish(victory: bool) -> void:
	var coins_before := SaveManager.get_coins()
	RunState.finish(victory)
	get_tree().paused = true
	var screen := EndScreen.new()
	add_child(screen)
	screen.open(victory, coins_before)
