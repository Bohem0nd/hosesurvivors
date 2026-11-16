extends Node
## Persistent progression (currency, unlocks, lifetime stats, settings) stored as JSON.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var data: Dictionary = _defaults()
## Tests set this to false so they never touch the real save file.
var persist: bool = true


func _ready() -> void:
	load_game()


func _defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"runs": 0,
		"wins": 0,
		"total_kills": 0,
		"best_time": 0.0,
		"best_level": 0,
		"unlocked_characters": ["jon_hose"],
		"settings": {"master_volume": 0.8, "music_volume": 0.6, "screen_shake": 1.0},
	}


func load_game() -> void:
	data = _defaults()
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		# Merge so that keys added in newer versions keep their defaults.
		for key: String in parsed:
			if data.has(key) and data[key] is Dictionary and parsed[key] is Dictionary:
				(data[key] as Dictionary).merge(parsed[key], true)
			else:
				data[key] = parsed[key]
	else:
		push_warning("Save file is corrupt; starting fresh.")


func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func get_coins() -> int:
	return int(data["coins"])


func is_unlocked(character: CharacterData) -> bool:
	return character.unlocked_by_default or (data["unlocked_characters"] as Array).has(String(character.id))


func get_setting(key: String, default: float = 1.0) -> float:
	return float((data["settings"] as Dictionary).get(key, default))


## Folds a finished run into lifetime progression and writes the save.
func record_run(victory: bool, time: float, kills: int, level: int, coins: int) -> void:
	data["runs"] = int(data["runs"]) + 1
	if victory:
		data["wins"] = int(data["wins"]) + 1
	data["total_kills"] = int(data["total_kills"]) + kills
	data["best_time"] = maxf(float(data["best_time"]), time)
	data["best_level"] = maxi(int(data["best_level"]), level)
	data["coins"] = int(data["coins"]) + coins
	save_game()
