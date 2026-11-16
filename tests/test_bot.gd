class_name TestBot
## Simple autopilots shared by the headless simulation and the screenshot tool.
##   kite    collects XP and dodges precisely - better than most humans
##   wander  collects XP but never dodges - a rough "inattentive player" proxy
##   idle    stands still


static func input(mode: String, ctx: GameContext, t: float) -> Vector2:
	if mode == "idle":
		return Vector2.ZERO
	var me := ctx.player.position
	var dir := Vector2(cos(t * 0.35), sin(t * 0.35)) * 0.5
	var best_d2 := 150.0 * 150.0
	var best := Vector2.INF
	for pickup in ctx.pickups.active:
		var d2 := pickup.position.distance_squared_to(me)
		if d2 < best_d2:
			best_d2 = d2
			best = pickup.position
	if best != Vector2.INF:
		dir += (best - me).normalized()
	if mode == "wander":
		return dir.normalized()
	var near: Array[Enemy] = []
	ctx.enemies.grid.query_circle(me, 46.0, near)
	for enemy in near:
		dir += (me - enemy.position).normalized() * 1.2
	return dir.normalized()


## Picks like a sensible player: evolution > weapon > damage passive > first card.
static func choose_card(offers: Array[UpgradeOffer]) -> int:
	var best := 0
	var best_score := -1
	for i in offers.size():
		var score := 0
		match offers[i].kind:
			UpgradeOffer.Kind.EVOLUTION:
				score = 4
			UpgradeOffer.Kind.WEAPON_LEVEL, UpgradeOffer.Kind.NEW_WEAPON:
				score = 3
			UpgradeOffer.Kind.PASSIVE:
				score = 2 if offers[i].upgrade.id == &"industrial_pressure" else 1
		if score > best_score:
			best_score = score
			best = i
	return best
