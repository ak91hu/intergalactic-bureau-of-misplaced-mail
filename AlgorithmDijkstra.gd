class_name AlgorithmDijkstra
extends AlgorithmBase

const INF: float = 1e9

var _dist: Dictionary = {}
var _prev: Dictionary = {}
var _visited: Dictionary = {}
var _pq: Array = []  # Array of [cost: float, node_id: String]
var _active_node: String = ""
var _active_cost: float = 0.0
var _active_neighbor_index: int = 0
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Dijkstra's Shortest Path"


func get_structure_label() -> String:
	return ">> PRIORITY QUEUE (cost, dept):"


func get_welcome_message() -> String:
	return "The Galactic GPS is online. We always expand the cheapest unvisited node next. NOTE: the -2 edge has been absolutized per Safety Reg DIJ-1138. Dijkstra cannot handle negative weights. It is ashamed."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_dist = {}
	_prev = {}
	_visited = {}
	_pq = []
	_active_node = ""
	_active_cost = 0.0
	_active_neighbor_index = 0
	_is_complete_flag = false
	_initialized = true

	for node_id: String in graph_data.keys():
		_dist[node_id] = INF
		_prev[node_id] = ""

	_dist[start_node] = 0.0
	_pq.append([0.0, start_node])

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "FORM DIJ-1138 — GALACTIC GPS ONLINE.\n%s (cost 0). All others: infinity. The meter is running, Director Zorp." % graph_data[start_node]["name"],
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
	while not _pq.is_empty():
		var entry: Array = _pq[0]
		_pq.pop_front()
		var cost: float = entry[0]
		var node_id: String = entry[1]

		if _visited.has(node_id):
			return {
				"state_changes": [],
				"structure": _build_structure_display(graph_data),
				"message": "STALE PQ ENTRY: %s (cost %d) — already finalized.\nDiscarded per Appendix DIJ-1138B. Classic lazy deletion. Gerald approves." % [graph_data[node_id]["name"], int(cost)],
				"is_complete": false
			}

		_active_node = node_id
		_active_cost = cost
		_active_neighbor_index = 0
		_visited[node_id] = true

		return {
			"state_changes": [{"id": _active_node, "state": "visited"}],
			"structure": _build_structure_display(graph_data),
			"message": "CHEAPEST: %s — %d credits. Finalized.\nNo cheaper path exists. Gerald files the receipt. Permanently." % [graph_data[_active_node]["name"], int(_active_cost)],
			"is_complete": false
		}

	_is_complete_flag = true
	return {
		"state_changes": [],
		"structure": [],
		"message": "DIJKSTRA COMPLETE — Optimal paths filed.\n%s" % _build_path_message(graph_data),
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
			"message": "%s — all neighbors checked. Back to the priority queue." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _visited.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s already finalized — we skip.\nWe do not re-open closed cases. Policy 7.7.7." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}

	# Use abs() for edge weight to handle the negative -2 edge safely
	var raw_weight: int = graph_data[_active_node]["weights"].get(neighbor_id, 0)
	var weight: float = float(abs(raw_weight))
	var new_dist: float = _active_cost + weight

	if new_dist < _dist[neighbor_id]:
		var old_str: String = "INF" if _dist[neighbor_id] >= INF else str(int(_dist[neighbor_id]))
		_dist[neighbor_id] = new_dist
		_prev[neighbor_id] = _active_node
		_pq.append([new_dist, neighbor_id])
		_pq.sort()
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "%s -> %s: cost %s -> %d. Improved!\nThe bureaucracy rejoices at this marginal %d-credit saving." % [graph_data[_active_node]["name"], graph_data[neighbor_id]["name"], old_str, int(new_dist), int(_dist[neighbor_id])],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s -> %s: %d is not better than %d. No update.\nStatus quo maintained. As is tradition." % [graph_data[_active_node]["name"], graph_data[neighbor_id]["name"], int(new_dist), int(_dist[neighbor_id])],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	# Only show non-stale PQ entries
	var shown: Dictionary = {}
	for entry in _pq:
		var node_id: String = entry[1]
		if not _visited.has(node_id) and not shown.has(node_id):
			result.append("[%d] — %s" % [int(entry[0]), graph_data[node_id]["name"]])
			shown[node_id] = true
	return result


func _build_path_message(graph_data: Dictionary) -> String:
	# Trace path to "destination" if reachable
	var target: String = "destination"
	if _dist[target] >= INF:
		return "Destination unreachable."

	var path: Array[String] = []
	var current: String = target
	while not current.is_empty():
		path.push_front(current)
		current = _prev[current]

	var path_names: Array = []
	for node_id: String in path:
		path_names.append(graph_data[node_id]["name"])

	return "%s — Total: %d credits. The mail MAY theoretically be deliverable." % [" -> ".join(path_names), int(_dist[target])]
