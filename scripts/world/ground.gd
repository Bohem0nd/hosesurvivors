class_name Ground
extends Node2D
## Infinite scrolling ground: a repeating tile that snaps along with the camera,
## plus deterministic per-chunk props (same props every time you revisit a spot).

const CHUNK := 256
const VIEW_CHUNKS := Vector2i(2, 2)  # chunks kept around the camera on each side

var _stage: StageData
var _camera: Node2D
var _tile: Sprite2D
var _tile_size: Vector2
var _decor_parent: Node2D
var _decor_pool: Array[Sprite2D] = []
var _current_chunk := Vector2i(99999, 99999)
var _total_weight: float = 0.0


## `decor_parent` should be the y-sorted entity layer so props sort with actors.
func setup(stage: StageData, camera: Node2D, decor_parent: Node2D) -> void:
	_stage = stage
	_camera = camera
	_decor_parent = decor_parent
	_tile_size = stage.ground_texture.get_size()
	_tile = Sprite2D.new()
	_tile.texture = stage.ground_texture
	_tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_tile.region_enabled = true
	_tile.modulate = stage.ground_tint
	var tiles := (Vector2(640.0, 360.0) / _tile_size).ceil() + Vector2(2.0, 2.0)
	_tile.region_rect = Rect2(Vector2.ZERO, tiles * _tile_size)
	add_child(_tile)
	for i in stage.decor.size():
		_total_weight += stage.decor_weights[i] if i < stage.decor_weights.size() else 1.0
	_update(true)


func _process(_delta: float) -> void:
	_update(false)


func _update(force: bool) -> void:
	var cam := _camera.position
	_tile.position = (cam / _tile_size).floor() * _tile_size + _tile_size * 0.5
	var chunk := Vector2i(floori(cam.x / CHUNK), floori(cam.y / CHUNK))
	if force or chunk != _current_chunk:
		_current_chunk = chunk
		_rebuild_decor()


func _rebuild_decor() -> void:
	if _stage.decor.is_empty():
		return
	var used := 0
	var rng := RandomNumberGenerator.new()
	for cy in range(_current_chunk.y - VIEW_CHUNKS.y, _current_chunk.y + VIEW_CHUNKS.y + 1):
		for cx in range(_current_chunk.x - VIEW_CHUNKS.x, _current_chunk.x + VIEW_CHUNKS.x + 1):
			rng.seed = hash(Vector2i(cx, cy)) ^ hash(_stage.id)
			for i in _stage.decor_per_chunk:
				var pos := Vector2(cx, cy) * CHUNK + Vector2(rng.randf(), rng.randf()) * CHUNK
				var tex := _pick_decor(rng.randf())
				var flip := rng.randf() < 0.5
				if pos.length() < 70.0:
					continue  # keep the starting area clear
				var sprite := _get_sprite(used)
				used += 1
				sprite.texture = tex
				sprite.offset = Vector2(0.0, -tex.get_height() * 0.5)
				sprite.position = pos.floor()
				sprite.flip_h = flip
				sprite.visible = true
	for i in range(used, _decor_pool.size()):
		_decor_pool[i].visible = false


func _pick_decor(roll: float) -> Texture2D:
	var r := roll * _total_weight
	for i in _stage.decor.size():
		r -= _stage.decor_weights[i] if i < _stage.decor_weights.size() else 1.0
		if r <= 0.0:
			return _stage.decor[i]
	return _stage.decor[_stage.decor.size() - 1]


func _get_sprite(i: int) -> Sprite2D:
	while _decor_pool.size() <= i:
		var s := Sprite2D.new()
		_decor_parent.add_child(s)
		_decor_pool.append(s)
	return _decor_pool[i]
