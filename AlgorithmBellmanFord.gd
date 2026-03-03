class_name AlgorithmBellmanFord
extends AlgorithmBase

const INF: int = 1 << 29  # ~537 million, safe sentinel for int arithmetic

var _dist: Dictionary = {}
var _prev: Dictionary = {}
var _edges: Array = []  # Array of [from_id, to_id, weight]
var _current_pass: int = 0
var _current_edge_index: int = 0
var _relaxed_in_pass: bool = false
var _is_complete_flag: bool = false
var _num_nodes: int = 0
var _start_node: String = ""


func get_name() -> String:
	return "Bellman-Ford"


func get_structure_label() -> String:
	return ">> DISTANCES (dept: cost):"


func get_welcome_message() -> String:
	return "Bellman-Ford handles NEGATIVE edge weights. Dijkstra cannot. This is Dijkstra's deepest shame. Up to 5 passes over all 7 edges. Watch the -2 shortcut slash 4 credits off the final path cost."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_dist = {}
	_prev = {}
	_edges = []
	_current_pass = 0
	_current_edge_index = 0
	_relaxed_in_pass = false
	_is_complete_flag = false
	_num_nodes = graph_data.size()
	_start_node = start_node
	_initialized = true

	# Initialize distances
	for node_id: String in graph_data.keys():
		_dist[node_id] = INF
		_prev[node_id] = ""
	_dist[start_node] = 0

	# Build flat edge list
	for from_id: String in graph_data.keys():
		for to_id: String in graph_data[from_id]["neighbors"]:
			var weight: int = graph_data[from_id]["weights"].get(to_id, 0)
			_edges.append([from_id, to_id, weight])

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "FORM BF-404 — NEGATIVE WEIGHTS WELCOME HERE.\n%s (cost 0). %d edges catalogued. The Bureau embraces debt." % [graph_data[start_node]["name"], _edges.size()],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	# Check if we've completed all passes
	if _current_pass >= _num_nodes - 1:
		return _finalize(graph_data)

	# Process one edge
	if _current_edge_index >= _edges.size():
		# End of current pass
		var pass_num: int = _current_pass + 1
		var relaxed: bool = _relaxed_in_pass
		_current_pass += 1
		_current_edge_index = 0
		_relaxed_in_pass = false

		if not relaxed:
			# Early termination: no relaxations in this pass
			_is_complete_flag = true
			return {
				"state_changes": [],
				"structure": _build_structure_display(graph_data),
				"message": "EARLY TERMINATION — Pass %d had zero improvements.\nConverged! No negative cycle detected. The Bureau's debts are finite. Probably.\n\n%s" % [pass_num, _build_path_message(graph_data)],
				"is_complete": true
			}

		if _current_pass >= _num_nodes - 1:
			return _finalize(graph_data)

		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "PASS %d DONE — improvements found, proceeding to pass %d.\nThe Bureau is thorough, if nothing else." % [pass_num, _current_pass + 1],
			"is_complete": false
		}

	# Relax one edge
	var edge: Array = _edges[_current_edge_index]
	_current_edge_index += 1
	var from_id: String = edge[0]
	var to_id: String = edge[1]
	var weight: int = edge[2]

	var state_changes: Array = []
	var msg: String
	var from_name: String = graph_data[from_id]["name"]
	var to_name: String = graph_data[to_id]["name"]

	if _dist[from_id] != INF and _dist[from_id] + weight < _dist[to_id]:
		var old_dist: int = _dist[to_id]
		_dist[to_id] = _dist[from_id] + weight
		_prev[to_id] = from_id
		_relaxed_in_pass = true

		var old_str: String = "INF" if old_dist == INF else str(old_dist)
		state_changes.append({"id": to_id, "state": "frontier"})
		msg = "RELAXED: %s -> %s (w=%d) — %s -> %d credits.\nNegative shortcut? We embrace it. Gerald is confused. That's normal." % [from_name, to_name, weight, old_str, _dist[to_id]]
	else:
		var from_str: String = "INF" if _dist[from_id] == INF else str(_dist[from_id])
		msg = "CHECKED: %s -> %s (w=%d) — source=%s, no improvement.\nMoving on. The status quo holds. Barely." % [from_name, to_name, weight, from_str]

	return {
		"state_changes": state_changes,
		"structure": _build_structure_display(graph_data),
		"message": msg,
		"is_complete": false,
		"examined_edge": {"from": from_id, "to": to_id}
	}


func is_complete() -> bool:
	return _is_complete_flag


func _finalize(graph_data: Dictionary) -> Dictionary:
	_is_complete_flag = true
	# Mark path nodes as visited
	var state_changes: Array = []
	var target: String = "destination"
	if _dist[target] < INF:
		var current: String = target
		while not current.is_empty():
			state_changes.append({"id": current, "state": "visited"})
			current = _prev[current]

	return {
		"state_changes": state_changes,
		"structure": _build_structure_display(graph_data),
		"message": "BF COMPLETE — %d passes executed.\n%s" % [_current_pass, _build_path_message(graph_data)],
		"is_complete": true
	}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for node_id: String in graph_data.keys():
		var cost: int = _dist.get(node_id, INF)
		var cost_str: String = "INF" if cost == INF else str(cost)
		result.append("%s: %s" % [graph_data[node_id]["name"], cost_str])
	return result


func _build_path_message(graph_data: Dictionary) -> String:
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

	return "%s — cost %d (Dijkstra would've said 9). One of them is correct. Hint: it's Bellman-Ford." % [" -> ".join(path_names), _dist[target]]
