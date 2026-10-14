class_name CourierLevels
extends RefCounted

const STATIONS: Array[String] = ["Indítóállomás", "Űrkikötő", "Holdposta", "Jeladó", "Archívum", "Célállomás", "Külső gyűrű", "Távoli kolónia"]
const POSITIONS: Array[Vector2] = [Vector2(0.08,0.46), Vector2(0.32,0.18), Vector2(0.32,0.76), Vector2(0.59,0.20), Vector2(0.59,0.75), Vector2(0.87,0.46), Vector2(0.87,0.86), Vector2(0.87,0.08)]

static func generate(algorithm: int, tier: int, variant: int = 0) -> Dictionary:
	algorithm = clampi(algorithm, 0, 8)
	tier = clampi(tier, 0, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261013 + algorithm * 1009 + tier * 101 + variant * 7919
	var nodes: Array = []
	var count: int = 6 + tier
	for index: int in range(count):
		var pos: Vector2 = POSITIONS[index]
		if variant % 2 != 0 and index in [1, 2, 3, 4]:
			pos.y = 1 - pos.y
		pos += Vector2(rng.randf_range(-0.012, 0.012), rng.randf_range(-0.012, 0.012))
		nodes.append({"id": String.chr(65 + index), "name": STATIONS[index], "position": pos})
	var edges: Array = []
	_add(edges, "A", "B", rng.randi_range(2, 4))
	_add(edges, "A", "C", rng.randi_range(1, 3))
	_add(edges, "B", "D", rng.randi_range(2, 4))
	_add(edges, "B", "E", -2 if algorithm in [4, 7] else rng.randi_range(5, 8))
	_add(edges, "C", "E", rng.randi_range(4, 7))
	_add(edges, "D", "F", rng.randi_range(3, 5))
	_add(edges, "E", "F", rng.randi_range(1, 3))
	if tier == 0 and variant % 3 == 1:
		_add(edges, "A", "E", rng.randi_range(10, 13))
	elif tier == 0 and variant % 3 == 2:
		_add(edges, "C", "D", rng.randi_range(5, 8))
	if tier >= 1:
		_add(edges, "F", "G", rng.randi_range(2, 4))
		_add(edges, "E", "G", rng.randi_range(7, 10))
		_add(edges, "A", "D", rng.randi_range(10, 13), variant % 3 == 1)
		_add(edges, "C", "D", rng.randi_range(6, 9), variant % 3 == 0)
		if variant % 3 == 2: edges[3]["closed"] = true
		if algorithm in [4, 7]:
			edges[2]["weight"] = -2
	if tier == 2:
		_add(edges, "F", "H", rng.randi_range(2, 4))
		_add(edges, "D", "H", rng.randi_range(10, 13))
		_add(edges, "B", "F", rng.randi_range(12, 16))
	# Each generated directed graph is acyclic; rebates cannot create negative cycles.
	var target: String = String.chr(65 + count - 1)
	var jobs: Array = [{"source": "A", "target": target}]
	if algorithm == 7 and tier == 2:
		jobs.append({"source": "B", "target": "G"})
	var data: Dictionary = {
		"algorithm": algorithm, "tier": tier, "variant": variant,
		"nodes": nodes, "edges": edges, "source": "A", "target": target,
		"directed": not CourierLessons.is_network(algorithm), "jobs": jobs,
		"sector": "%02d-%02d" % [algorithm + 1, tier + 1],
		"hazard": "Ionvihar: a szaggatott sáv le van zárva." if tier > 0 else "Minden postasáv járható.",
		"guided": tier == 0
	}
	return data

static func _add(edges: Array, from: String, to: String, weight: int, closed: bool = false) -> void:
	edges.append({"from": from, "to": to, "weight": weight, "closed": closed, "key": from + "|" + to})
