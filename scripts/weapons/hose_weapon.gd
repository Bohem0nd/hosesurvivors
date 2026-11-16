class_name HoseWeapon
extends Weapon
## A hose: sweeps toward the nearest enemy and sprays bursts of piercing
## droplets. Used by The Holy Hose and (with different data) The Hose of Judgment.
##
## data.params:
##   stream_rate  droplets per second per jet while spraying
##   fan_deg      angle between adjacent jets
##   jitter_deg   random spread per droplet
##   turn_rate    radians/second the nozzle can swing
##   sweep_deg    side-to-side sweep while spraying
##   shake        camera shake per burst (for the big evolved hose)

const TAIL_POINTS := 9
const TAIL_SEGMENT := 5.0
const RETARGET_TIME := 0.12

var _aim: float = 0.0
var _burst_left: float = 0.0
var _cooldown_left: float = 0.4
var _emit_accum: float = 0.0
var _retarget_t: float = 0.0
var _target: Enemy
var _spray_t: float = 0.0

var _nozzle: Sprite2D
var _tail: Line2D
var _tail_pts := PackedVector2Array()


func _on_setup() -> void:
	_nozzle = Sprite2D.new()
	_nozzle.texture = data.visual_texture
	_nozzle.offset = Vector2(6.0, 0.0)
	_nozzle.z_index = 1
	add_child(_nozzle)

	# The hose itself trails behind the wielder like a lazy rope.
	_tail = Line2D.new()
	_tail.top_level = true
	_tail.width = 3.0
	_tail.default_color = Color("38683c")
	_tail.joint_mode = Line2D.LINE_JOINT_ROUND
	_tail.z_index = -1
	add_child(_tail)
	for i in TAIL_POINTS:
		_tail_pts.append(player.position + Vector2(-TAIL_SEGMENT * i, 8.0))
	_tail.points = _tail_pts


func _process(delta: float) -> void:
	_update_target(delta)
	var origin := player.position
	var desired := player.facing.angle()
	if _target != null:
		desired = (_target.position - origin).angle()
	_aim = rotate_toward(_aim, desired, float(data.params.get("turn_rate", 9.0)) * delta)

	if _burst_left > 0.0:
		_spray(delta, origin)
	else:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0 and _target != null:
			_burst_left = get_duration()
			_spray_t = 0.0
			AudioManager.play(data.fire_sfx, -5.0)
			var shake: float = data.params.get("shake", 0.0)
			if shake > 0.0:
				ctx.camera.shake(shake)

	_nozzle.rotation = _aim
	_nozzle.flip_v = absf(_aim) > PI * 0.5
	_nozzle.position = Vector2(0.0, 2.0) + Vector2.from_angle(_aim) * 3.0
	_update_tail(origin)


func _update_target(delta: float) -> void:
	_retarget_t -= delta
	if _retarget_t > 0.0 and _target != null and _target.alive:
		return
	_retarget_t = RETARGET_TIME
	_target = ctx.enemies.nearest(player.position, get_range() * 1.05)


func _spray(delta: float, origin: Vector2) -> void:
	_burst_left -= delta
	_spray_t += delta
	_emit_accum += float(data.params.get("stream_rate", 20.0)) * delta
	var sweep := deg_to_rad(float(data.params.get("sweep_deg", 5.0))) * sin(_spray_t * 14.0)
	while _emit_accum >= 1.0:
		_emit_accum -= 1.0
		_emit(origin, _aim + sweep)
	if _burst_left <= 0.0:
		_cooldown_left = get_cooldown()


func _emit(origin: Vector2, aim: float) -> void:
	var count := get_projectile_count()
	var fan := deg_to_rad(float(data.params.get("fan_deg", 14.0)))
	var jitter := deg_to_rad(float(data.params.get("jitter_deg", 3.0)))
	var dmg := get_damage()
	var knock := get_knockback()
	var pierce := get_pierce()
	var size := get_area()
	var lifetime := get_range() / data.projectile.speed
	for i in count:
		var ang := aim + (float(i) - float(count - 1) * 0.5) * fan + randf_range(-jitter, jitter)
		var dir := Vector2.from_angle(ang)
		var muzzle := origin + Vector2(0.0, 2.0) + dir * 14.0
		ctx.projectiles.spawn(data.projectile, muzzle, dir, dmg, knock, pierce, size,
				lifetime * randf_range(0.9, 1.05))
		if randf() < 0.5:
			ctx.particles.emit(muzzle, dir.rotated(randf_range(-0.6, 0.6)) * randf_range(40.0, 110.0),
					0.22, Color(0.8, 0.93, 1.0), 1.0)


## Each point follows the previous one at a fixed distance (cheap rope).
func _update_tail(origin: Vector2) -> void:
	_tail_pts[0] = origin + Vector2(0.0, 3.0) - Vector2.from_angle(_aim) * 2.0
	for i in range(1, TAIL_POINTS):
		var prev := _tail_pts[i - 1]
		var diff := _tail_pts[i] - prev
		var d := diff.length()
		if d > TAIL_SEGMENT:
			_tail_pts[i] = prev + diff / d * TAIL_SEGMENT
	_tail.points = _tail_pts
