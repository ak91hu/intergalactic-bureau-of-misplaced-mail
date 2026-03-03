class_name AlgorithmAStar
extends AlgorithmBase

const INF: float = 1e9

# Admissible h-values (using abs edge weights, treats -2 as 2)
const H_VALUES: Dictionary = {
	"redundancy": 5, "forms": 6, "delays": 10,
	"stamps": 1, "lost": 4, "destination": 0
}

var _g: Dictionary = {}
var _open: Array = []        # Array of [f: float, g: float, node_id: String]
var _closed: Dictionary = {}
var _prev: Dictionary = {}
var _active_node: String = ""
var _active_cost: float = 0.0
var _active_neighbor_index: int = 0
var _is_complete_flag: bool = false


func get_name() -> String:
	return "A* Search"


func get_structure_label() -> String:
	return ">> OPEN SET (f=g+h):"


func get_welcome_message() -> String:
	return "A* = Dijkstra with a heuristic gut feeling. f = g + h. Lowest f expanded first. The Delays Dept has h=10 and will be skipped entirely. The heuristic never lies. Allegedly."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_g = {}
	_open = []
	_closed = {}
	_prev = {}
	_active_node = ""
	_active_cost = 0.0
	_active_neighbor_index = 0
	_is_complete_flag = false
	_initialized = true

	for node_id: String in graph_data.keys():
		_g[node_id] = INF
		_prev[node_id] = ""

	_g[start_node] = 0.0
	var h: float = float(H_VALUES.get(start_node, 0))
	_open.append([h, 0.0, start_node])

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "FORM ASTAR-H1 — HEURISTIC GUIDANCE LOADED.\n%s: g=0, h=%d, f=%d. The Force guides us. (Or the heuristic. Same energy.)" % [graph_data[start_node]["name"], int(h), int(h)],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _active_node.is_empty():
		return _extract_min(graph_data)
	else:
		return _relax_next_neighbor(graph_data)


func is_complete() -> bool:
	return _is_complete_flag


func _extract_min(graph_data: Dictionary) -> Dictionary:
	while not _open.is_empty():
		var entry: Array = _open[0]
		_open.pop_front()
		var f: float = entry[0]
		var g: float = entry[1]
		var node_id: String = entry[2]

		if _closed.has(node_id):
			return {
				"state_changes": [],
				"structure": _build_structure_display(graph_data),
				"message": "STALE OPEN ENTRY: %s (f=%d) — already closed.\nDiscarded per Protocol H-1B. Gerald didn't file it right. He never does." % [graph_data[node_id]["name"], int(f)],
				"is_complete": false
			}

		_active_node = node_id
		_active_cost = g
		_active_neighbor_index = 0
		_closed[node_id] = true

		if node_id == "destination":
			_is_complete_flag = true
			return {
				"state_changes": [{"id": _active_node, "state": "visited"}],
				"structure": _build_structure_display(graph_data),
				"message": "TARGET REACHED! %s — f=%d (g=%d + h=0).\nA* skipped Delays entirely (h=10). Heuristic: correct. Gerald: surprised.\n\n%s" % [graph_data[_active_node]["name"], int(f), int(g), _build_path_message(graph_data)],
				"is_complete": true
			}

		var h: float = float(H_VALUES.get(node_id, 0))
		return {
			"state_changes": [{"id": _active_node, "state": "visited"}],
			"structure": _build_structure_display(graph_data),
			"message": "EXPANDING: %s — f=%d (g=%d + h=%d). Now closed.\nNeighbors evaluated next. The heuristic trusts this choice." % [graph_data[_active_node]["name"], int(f), int(g), int(h)],
			"is_complete": false
		}

	_is_complete_flag = true
	return {
		"state_changes": [],
		"structure": [],
		"message": "A* COMPLETE — OPEN SET exhausted.\n%s" % _build_path_message(graph_data),
		"is_complete": true
	}


func _relax_next_neighbor(graph_data: Dictionary) -> Dictionary:
	var neighbors: Array = graph_data[_active_node]["neighbors"]

	if _active_neighbor_index >= neighbors.size():
		var completed_node: String = _active_node
		_active_node = ""
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s — neighbors done. Next minimum-f from OPEN SET." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _closed.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s CLOSED — already optimal. Skipping.\nA* guarantees correctness. Gerald lost the proof but trusts it." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}

	var raw_weight: int = graph_data[_active_node]["weights"].get(neighbor_id, 0)
	var weight: float = float(abs(raw_weight))
	var new_g: float = _active_cost + weight
	var h: float = float(H_VALUES.get(neighbor_id, 0))
	var new_f: float = new_g + h

	if new_g < _g[neighbor_id]:
		_g[neighbor_id] = new_g
		_prev[neighbor_id] = _active_node
		_open.append([new_f, new_g, neighbor_id])
		_open.sort()
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "%s — f=%d (g=%d + h=%d), via %s.\nAdded to OPEN SET. The heuristic says this route looks promising." % [graph_data[neighbor_id]["name"], int(new_f), int(new_g), int(h), graph_data[_active_node]["name"]],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s — g=%d not better than existing g=%d. No update.\nExisting path holds. Status quo. Tradition." % [graph_data[neighbor_id]["name"], int(new_g), int(_g[neighbor_id])],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	var shown: Dictionary = {}
	for entry: Array in _open:
		var node_id: String = entry[2]
		if not _closed.has(node_id) and not shown.has(node_id):
			result.append("[f=%d g=%d] — %s" % [int(entry[0]), int(entry[1]), graph_data[node_id]["name"]])
			shown[node_id] = true
	return result


func _build_path_message(graph_data: Dictionary) -> String:
	var target: String = "destination"
	if _g[target] >= INF:
		return "Destination unreachable."

	var path: Array[String] = []
	var current: String = target
	while not current.is_empty():
		path.push_front(current)
		current = _prev[current]

	var path_names: Array = []
	for node_id: String in path:
		path_names.append(graph_data[node_id]["name"])

	return "%s — Total: %d credits. Director Zorp: satisfied." % [" -> ".join(path_names), int(_g[target])]
