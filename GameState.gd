extends Node

var SAVE_PATH: String = "user://bureau_progress.cfg"
const MAX_SCORE: int = 425
var selected_algorithm: int = 0
var practice_mode: bool = false
var sound_enabled: bool = true
var music_enabled: bool = true
var music_volume: float = 0.22
var reduced_motion: bool = false
var best_scores: Dictionary = {}
var medals: Dictionary = {}
var courier_algorithm: int = 0
var courier_tier: int = 0
var courier_variant: int = 0
var courier_scores: Dictionary = {}
var courier_medals: Dictionary = {}
var tree_kind: int = 2
var tree_tier: int = 0
var tree_variant: int = 0
var tree_scores: Dictionary = {}
var tree_medals: Dictionary = {}
var last_save_error: Error = OK

func _ready() -> void:
	load_progress()

func load_progress(path: String = "") -> void:
	if path.is_empty(): path = SAVE_PATH
	var save := ConfigFile.new()
	if save.load(path) != OK:
		return
	best_scores.clear()
	medals.clear()
	courier_scores.clear()
	courier_medals.clear()
	tree_scores.clear()
	tree_medals.clear()
	for index: int in range(9):
		var score: Variant = save.get_value("scores", str(index), 0)
		var medal: Variant = save.get_value("medals", str(index), 0)
		if (score is int or score is float) and score > 0:
			best_scores[index] = clampi(int(score), 0, MAX_SCORE)
		if (medal is int or medal is float) and medal > 0:
			medals[index] = clampi(int(medal), 0, 3)
		for tier: int in range(3):
			var key: String = CourierLessons.key(index, tier)
			var courier_score: Variant = save.get_value("courier_scores", key, 0)
			var courier_medal: Variant = save.get_value("courier_medals", key, 0)
			if (courier_score is int or courier_score is float) and courier_score > 0:
				courier_scores[key] = clampi(int(courier_score), 0, 1000)
			if (courier_medal is int or courier_medal is float) and courier_medal > 0:
				courier_medals[key] = clampi(int(courier_medal), 0, 3)
	sound_enabled = save.get_value("settings", "sound", true) == true
	music_enabled = save.get_value("settings", "music", true) == true
	var volume: Variant = save.get_value("settings", "music_volume", 0.22)
	music_volume = clampf(float(volume), 0, 1) if volume is float or volume is int else 0.22
	for kind: int in range(3):
		for tier: int in range(3):
			var key: String = "%d:%d" % [kind, tier]
			var score: Variant = save.get_value("tree_scores", key, 0)
			var medal: Variant = save.get_value("tree_medals", key, 0)
			if (score is int or score is float) and score > 0: tree_scores[key] = clampi(int(score), 0, 1000)
			if (medal is int or medal is float) and medal > 0: tree_medals[key] = clampi(int(medal), 0, 3)
	reduced_motion = save.get_value("settings", "reduced_motion", false) == true

func save_progress(path: String = "") -> Error:
	if path.is_empty(): path = SAVE_PATH
	var save := ConfigFile.new()
	for index: int in best_scores:
		save.set_value("scores", str(index), best_scores[index])
	for index: int in medals:
		save.set_value("medals", str(index), medals[index])
	for key: String in courier_scores:
		save.set_value("courier_scores", key, courier_scores[key])
	for key: String in courier_medals:
		save.set_value("courier_medals", key, courier_medals[key])
	for key: String in tree_scores: save.set_value("tree_scores", key, tree_scores[key])
	for key: String in tree_medals: save.set_value("tree_medals", key, tree_medals[key])
	save.set_value("settings", "sound", sound_enabled)
	save.set_value("settings", "music", music_enabled)
	save.set_value("settings", "music_volume", music_volume)
	save.set_value("settings", "reduced_motion", reduced_motion)
	last_save_error = save.save(path)
	return last_save_error

func record_result(index: int, score: int, stars: int, path: String = "") -> void:
	if index < 0 or index >= 9:
		return
	best_scores[index] = maxi(best_scores.get(index, 0), clampi(score, 0, MAX_SCORE))
	medals[index] = maxi(medals.get(index, 0), clampi(stars, 1, 3))
	save_progress(path)

func total_xp() -> int:
	var total: int = 0
	for score: int in best_scores.values():
		total += score
	return total

func recommended_algorithm() -> int:
	for index: int in range(9):
		if not medals.has(index):
			return index
	return selected_algorithm

func daily_algorithm() -> int:
	return int(floor(Time.get_unix_time_from_system() / 86400.0)) % 9

func record_courier(algorithm: int, tier: int, score: int, stars: int, path: String = "") -> void:
	if algorithm < 0 or algorithm > 8 or tier < 0 or tier > 2: return
	var key: String = CourierLessons.key(algorithm, tier)
	courier_scores[key] = maxi(courier_scores.get(key, 0), clampi(score, 0, 1000))
	courier_medals[key] = maxi(courier_medals.get(key, 0), clampi(stars, 1, 3))
	save_progress(path)

func courier_xp() -> int:
	var total: int = 0
	for value: int in courier_scores.values(): total += value
	return total

func recommended_courier() -> Dictionary:
	for algorithm: int in range(9):
		for tier: int in range(3):
			if not courier_medals.has(CourierLessons.key(algorithm, tier)):
				return {"algorithm": algorithm, "tier": tier}
	return {"algorithm": courier_algorithm, "tier": courier_tier}

func record_tree(kind: int, tier: int, score: int, stars: int, path: String = "") -> void:
	if kind < 0 or kind > 2 or tier < 0 or tier > 2: return
	var key: String = "%d:%d" % [kind, tier]
	tree_scores[key] = maxi(tree_scores.get(key, 0), clampi(score, 0, 1000))
	tree_medals[key] = maxi(tree_medals.get(key, 0), clampi(stars, 1, 3))
	save_progress(path)
