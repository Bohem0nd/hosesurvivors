class_name Stats
## Canonical stat names and their defaults. Any system may read these from a StatBlock.
## Tag-scoped damage stats are named "damage_<tag>" (e.g. damage_water) and default to 1.

const MAX_HEALTH := &"max_health"
const MOVE_SPEED := &"move_speed"
const DAMAGE := &"damage"                  # global damage multiplier
const ATTACK_SPEED := &"attack_speed"      # divides weapon cooldowns
const COOLDOWN := &"cooldown"              # multiplies weapon cooldowns (lower is better)
const AREA := &"area"
const PROJECTILE_COUNT := &"projectile_count"  # flat bonus projectiles
const ARMOR := &"armor"                    # damage resistance, 0..0.8
const PICKUP_RADIUS := &"pickup_radius"
const XP_GAIN := &"xp_gain"
const REGEN := &"regen"                    # health per second
const KNOCKBACK := &"knockback"
const DURATION := &"duration"
const COIN_GAIN := &"coin_gain"

const DEFAULTS := {
	MAX_HEALTH: 100.0,
	MOVE_SPEED: 90.0,
	DAMAGE: 1.0,
	ATTACK_SPEED: 1.0,
	COOLDOWN: 1.0,
	AREA: 1.0,
	PROJECTILE_COUNT: 0.0,
	ARMOR: 0.0,
	PICKUP_RADIUS: 36.0,
	XP_GAIN: 1.0,
	REGEN: 0.0,
	KNOCKBACK: 1.0,
	DURATION: 1.0,
	COIN_GAIN: 1.0,
}
