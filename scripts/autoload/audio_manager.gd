extends Node
## Central audio hooks. Gameplay code calls AudioManager.play(&"id"); the id maps to
## res://assets/audio/sfx/<id>.wav (or .ogg). Missing files are silently ignored, so
## hooks can exist before their final sounds do.

const SFX_DIR := "res://assets/audio/sfx/"
const VOICES := 14
const MIN_INTERVAL := 0.045  # seconds between two plays of the same id

var _streams: Dictionary = {}     # StringName -> AudioStream or null
var _last_played: Dictionary = {} # StringName -> msec
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(func() -> void:
		if _music.stream != null:
			_music.play())
	apply_volume()


func apply_volume() -> void:
	var master := SaveManager.get_setting("master_volume", 0.8)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))
	_music.volume_db = linear_to_db(maxf(SaveManager.get_setting("music_volume", 0.6), 0.0001)) - 8.0


func play(id: StringName, volume_db: float = 0.0, pitch_variance: float = 0.08) -> void:
	if id == &"":
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(id, -1000)) < int(MIN_INTERVAL * 1000.0):
		return
	var stream := _get_stream(id)
	if stream == null:
		return
	_last_played[id] = now
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	voice.play()


func play_music(stream: AudioStream) -> void:
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	if stream != null:
		_music.play()
	else:
		_music.stop()


func stop_music() -> void:
	_music.stop()
	_music.stream = null


func _get_stream(id: StringName) -> AudioStream:
	if not _streams.has(id):
		var found: AudioStream = null
		for ext: String in [".wav", ".ogg"]:
			var path := SFX_DIR + String(id) + ext
			if ResourceLoader.exists(path):
				found = load(path)
				break
		_streams[id] = found
	return _streams[id]


func _exit_tree() -> void:
	# Release streams so nothing is reported as leaked at shutdown.
	stop_music()
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()
