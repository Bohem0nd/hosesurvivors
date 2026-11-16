class_name PickupManager
extends Node2D
## XP droplets, coins, healing cans, magnets and supply crates.
## Pickups idle until the player's pickup radius touches them, then home in.

const TEX_XP_SMALL := preload("res://assets/sprites/pickups/xp_small.png")
const TEX_XP_MEDIUM := preload("res://assets/sprites/pickups/xp_medium.png")
const TEX_XP_LARGE := preload("res://assets/sprites/pickups/xp_large.png")
const TEX_COIN := preload("res://assets/sprites/pickups/coin.png")
const TEX_HEAL := preload("res://assets/sprites/pickups/kristall.png")
const TEX_CRATE := preload("res://assets/sprites/pickups/supply_crate.png")
const TEX_MAGNET := preload("res://assets/sprites/pickups/magnet.png")

const MAX_XP_PICKUPS := 350
const COLLECT_DISTANCE := 7.0
const HEAL_DROP_CHANCE := 0.006
const MAGNET_DROP_CHANCE := 0.0015
const HEAL_AMOUNT := 25.0

var ctx: GameContext
var active: Array[Pickup] = []
var _pool: ObjectPool
var _xp_count: int = 0
## XP that could not get its own pickup (cap reached); folded into the next drop.
var _overflow_xp: float = 0.0


func setup(p_ctx: GameContext, prewarm: int = 150) -> void:
	ctx = p_ctx
	_pool = ObjectPool.new(self, func() -> Node: return Pickup.new(), prewarm)


func drop_rewards(data: EnemyData, pos: Vector2) -> void:
	if data.xp_value > 0:
		if data.tier == EnemyData.Tier.NORMAL:
			spawn(Pickup.Kind.XP, pos, data.xp_value)
		else:
			# Elites and bosses burst into a shower of droplets.
			var pieces := 6 if data.tier == EnemyData.Tier.ELITE else 16
			for i in pieces:
				spawn(Pickup.Kind.XP, pos, float(data.xp_value) / pieces, 30.0)
	if randf() < data.coin_chance:
		spawn(Pickup.Kind.COIN, pos, 1.0 if data.tier == EnemyData.Tier.NORMAL else 10.0, 12.0)
	if data.drops_crate:
		spawn(Pickup.Kind.CRATE, pos, 1.0)
	elif randf() < HEAL_DROP_CHANCE:
		spawn(Pickup.Kind.HEAL, pos, HEAL_AMOUNT, 10.0)
	elif randf() < MAGNET_DROP_CHANCE:
		spawn(Pickup.Kind.MAGNET, pos, 1.0, 10.0)


func spawn(kind: Pickup.Kind, pos: Vector2, value: float, scatter: float = 0.0) -> void:
	if kind == Pickup.Kind.XP:
		if _xp_count >= MAX_XP_PICKUPS:
			_overflow_xp += value
			return
		value += _overflow_xp
		_overflow_xp = 0.0
		_xp_count += 1
	var p: Pickup = _pool.acquire()
	p.kind = kind
	p.value = value
	p.attracted = false
	p.speed = 0.0
	p.age = 0.0
	p.position = pos
	p.scatter = Vector2.from_angle(randf() * TAU) * randf_range(scatter * 0.5, scatter) * 4.0
	p.texture = _texture_for(kind, value)
	p.index = active.size()
	active.append(p)


func _texture_for(kind: Pickup.Kind, value: float) -> Texture2D:
	match kind:
		Pickup.Kind.COIN:
			return TEX_COIN
		Pickup.Kind.HEAL:
			return TEX_HEAL
		Pickup.Kind.CRATE:
			return TEX_CRATE
		Pickup.Kind.MAGNET:
			return TEX_MAGNET
	if value >= 20.0:
		return TEX_XP_LARGE
	return TEX_XP_MEDIUM if value >= 4.0 else TEX_XP_SMALL


## Pulls every XP droplet on the map to the player.
func attract_all() -> void:
	for p in active:
		if p.kind == Pickup.Kind.XP or p.kind == Pickup.Kind.COIN:
			p.attracted = true


func _process(delta: float) -> void:
	if ctx == null or not ctx.player.alive:
		return
	var player := ctx.player
	var target := player.position
	var radius := player.stats.get_stat(Stats.PICKUP_RADIUS)
	var radius2 := radius * radius
	var i := active.size() - 1
	while i >= 0:
		var p := active[i]
		i -= 1
		p.age += delta
		if p.scatter != Vector2.ZERO:
			p.position += p.scatter * delta
			p.scatter *= maxf(0.0, 1.0 - 8.0 * delta)
			if p.scatter.length_squared() < 4.0:
				p.scatter = Vector2.ZERO
		var d2 := p.position.distance_squared_to(target)
		if not p.attracted:
			if d2 < radius2 and p.age > 0.15:
				p.attracted = true
				p.speed = -60.0  # brief recoil before it rushes in
			continue
		p.speed = minf(p.speed + 700.0 * delta, 420.0)
		p.position = p.position.move_toward(target, p.speed * delta) if p.speed > 0.0 \
				else p.position - (target - p.position).normalized() * -p.speed * delta
		if d2 < COLLECT_DISTANCE * COLLECT_DISTANCE:
			_collect(p)


func _collect(p: Pickup) -> void:
	var player := ctx.player
	match p.kind:
		Pickup.Kind.XP:
			_xp_count -= 1
			RunState.add_xp(maxi(1, roundi(p.value * player.stats.get_stat(Stats.XP_GAIN))))
			AudioManager.play(&"xp_pickup", -8.0, 0.15)
		Pickup.Kind.COIN:
			RunState.add_coins(maxi(1, roundi(p.value * player.stats.get_stat(Stats.COIN_GAIN))))
			AudioManager.play(&"coin_pickup", -6.0)
		Pickup.Kind.HEAL:
			player.heal(p.value)
			AudioManager.play(&"heal")
		Pickup.Kind.MAGNET:
			attract_all()
			AudioManager.play(&"crate_open", -4.0)
		Pickup.Kind.CRATE:
			AudioManager.play(&"crate_open")
			Events.crate_collected.emit()
	var last: Pickup = active[active.size() - 1]
	active[p.index] = last
	last.index = p.index
	active.pop_back()
	p.index = -1
	_pool.release(p)
