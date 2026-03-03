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
	return "Welcome to the Intergalactic Bureau of Misplaced Mail.\n\nBellman-Ford finds the shortest path even through negative-weight edges — something Dijkstra refuses to handle. We will run up to |V|−1 = 5 passes over all edges, relaxing distances one edge at a time.\n\nPress 'Process Next Memo' to begin."


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
		"message": "BELLMAN-FORD ALGORITHM — FORM BF-404\nRE: Negative-Weight Shortest Path Protocol\n\nStarting at the %s (cost: 0). All other departments: ∞.\n\n%d edges catalogued. Will run %d passes. Each pass checks every edge. Unlike Dijkstra, we embrace negative weights. They are simply debts, and the Bureau has many." % [graph_data[start_node]["name"], _edges.size(), _num_nodes - 1],
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
				"message": "EARLY TERMINATION — Pass %d of %d\n\nNo distances were improved in this pass. The algorithm has converged early. No negative cycles detected. The Bureau's debts are finite after all.\n\n%s" % [pass_num, _num_nodes - 1, _build_path_message(graph_data)],
				"is_complete": true
			}

		if _current_pass >= _num_nodes - 1:
			return _finalize(graph_data)

		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "PASS %d COMPLETE — %d relaxations occurred\n\nAll edges have been examined once. Beginning Pass %d of %d. The Bureau is thorough, if nothing else." % [pass_num, _edges.size(), _current_pass + 1, _num_nodes - 1],
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
	var edge_label: String = "%s → %s (weight: %d)" % [graph_data[from_id]["name"], graph_data[to_id]["name"], weight]

	if _dist[from_id] != INF and _dist[from_id] + weight < _dist[to_id]:
		var old_dist: int = _dist[to_id]
		_dist[to_id] = _dist[from_id] + weight
		_prev[to_id] = from_id
		_relaxed_in_pass = true

		var old_str: String = "∞" if old_dist == INF else str(old_dist)
		state_changes.append({"id": to_id, "state": "frontier"})
		msg = "RELAXATION — Pass %d, Edge %d:\n%s\n\nDistance improved: %s → %d. The negative weight on this corridor has made it surprisingly efficient. The Bureau grudgingly updates its records." % [_current_pass + 1, _current_edge_index, edge_label, old_str, _dist[to_id]]
	else:
		var from_str: String = "∞" if _dist[from_id] == INF else str(_dist[from_id])
		msg = "NO RELAXATION — Pass %d, Edge %d:\n%s\n\nSource distance: %s. No improvement possible. The existing path holds. This edge has been examined and found wanting." % [_current_pass + 1, _current_edge_index, edge_label, from_str]

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
		"message": "BELLMAN-FORD COMPLETE — %d passes executed\n\nNo negative cycles detected (if there were, distances would keep decreasing — they did not).\n\n%s" % [_current_pass, _build_path_message(graph_data)],
		"is_complete": true
	}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for node_id: String in graph_data.keys():
		var cost: int = _dist.get(node_id, INF)
		var cost_str: String = "∞" if cost == INF else str(cost)
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

	return "Shortest path to Actual Mail Delivery*:\n%s\nTotal cost: %d (negative edges included)" % [" → ".join(path_names), _dist[target]]
