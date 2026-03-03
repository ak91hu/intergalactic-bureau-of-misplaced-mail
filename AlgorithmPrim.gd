class_name AlgorithmPrim
extends AlgorithmBase

const INF: float = 1e9

var _in_mst: Dictionary = {}
var _key: Dictionary = {}    # minimum cost to connect node to MST
var _parent: Dictionary = {} # which MST node connects to this node
var _pq: Array = []          # Array of [cost: float, node_id: String]
var _mst_edges: Array = []   # Array of [from_id, to_id, cost]
var _undirected: Dictionary = {}  # node_id -> {neighbor_id: weight}
var _active_node: String = ""
var _active_neighbor_index: int = 0
var _active_neighbors: Array = []
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Prim's MST"


func get_structure_label() -> String:
	return ">> MST CANDIDATES (cost, dept):"


func get_welcome_message() -> String:
	return "Prim grows the cheapest possible network one connection at a time. Graph treated as undirected. Negative weights absolutized per Policy MST-42. No cycles permitted. That is THE rule. Ask Gerald."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_in_mst = {}
	_key = {}
	_parent = {}
	_pq = []
	_mst_edges = []
	_undirected = {}
	_active_node = ""
	_active_neighbor_index = 0
	_active_neighbors = []
	_is_complete_flag = false
	_initialized = true

	# Build undirected adjacency using abs(weight)
	for node_id: String in graph_data.keys():
		_undirected[node_id] = {}
	for node_id: String in graph_data.keys():
		for neighbor_id: String in graph_data[node_id]["neighbors"]:
			var weight: float = float(abs(graph_data[node_id]["weights"].get(neighbor_id, 0)))
			# Only set if not already set with a lower weight (keep minimum)
			if not _undirected[node_id].has(neighbor_id) or weight < _undirected[node_id][neighbor_id]:
				_undirected[node_id][neighbor_id] = weight
			if not _undirected[neighbor_id].has(node_id) or weight < _undirected[neighbor_id][node_id]:
				_undirected[neighbor_id][node_id] = weight

	# Initialize keys to INF
	for node_id: String in graph_data.keys():
		_key[node_id] = INF
		_parent[node_id] = ""

	_key[start_node] = 0.0
	_pq.append([0.0, start_node])

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "FORM MST-42 — NETWORK EXPANSION AUTHORIZED.\n%s selected as root. Undirected graph built. The tree is lonely. It has feelings." % graph_data[start_node]["name"],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _active_node.is_empty():
		return _extract_min(graph_data)
	else:
		return _update_next_neighbor(graph_data)


func is_complete() -> bool:
	return _is_complete_flag


func _extract_min(graph_data: Dictionary) -> Dictionary:
	while not _pq.is_empty():
		var entry: Array = _pq[0]
		_pq.pop_front()
		var cost: float = entry[0]
		var node_id: String = entry[1]

		if _in_mst.has(node_id):
			return {
				"state_changes": [],
				"structure": _build_structure_display(graph_data),
				"message": "STALE CANDIDATE: %s (cost %d) — already in tree.\nLazy deletion applied per Annex MST-42C. Gerald was not notified." % [graph_data[node_id]["name"], int(cost)],
				"is_complete": false
			}

		_active_node = node_id
		_active_neighbor_index = 0
		_active_neighbors = _undirected[node_id].keys()
		_in_mst[node_id] = true

		if not _parent[node_id].is_empty():
			_mst_edges.append([_parent[node_id], node_id, cost])

		var parent_str: String = "root (no parent)" if _parent[node_id].is_empty() else graph_data[_parent[node_id]]["name"]

		return {
			"state_changes": [{"id": _active_node, "state": "visited"}],
			"structure": _build_structure_display(graph_data),
			"message": "ADDED TO MST: %s — %d credits via %s.\nThe network grows. Director Zorp approves. Marginally." % [graph_data[_active_node]["name"], int(cost), parent_str],
			"is_complete": false
		}

	# PQ empty — check if MST is complete
	_is_complete_flag = true
	return {
		"state_changes": [],
		"structure": [],
		"message": "MST COMPLETE — STATUS: Minimally Connected.\n%s" % _build_mst_message(graph_data),
		"is_complete": true
	}


func _update_next_neighbor(graph_data: Dictionary) -> Dictionary:
	if _active_neighbor_index >= _active_neighbors.size():
		var completed_node: String = _active_node
		_active_node = ""

		# Check if MST is complete (all nodes in)
		if _in_mst.size() >= graph_data.size():
			_is_complete_flag = true
			return {
				"state_changes": [],
				"structure": [],
				"message": "MST COMPLETE — STATUS: Minimally Connected.\n%s" % _build_mst_message(graph_data),
				"is_complete": true
			}

		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s — all neighbors evaluated. Fetching next cheapest from PQ." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = _active_neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _in_mst.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s already in tree — NO CYCLES.\nThat is THE rule. THE rule. Gerald knows the rule." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}

	var weight: float = _undirected[_active_node].get(neighbor_id, INF)

	if weight < _key[neighbor_id]:
		_key[neighbor_id] = weight
		_parent[neighbor_id] = _active_node
		_pq.append([weight, neighbor_id])
		_pq.sort()
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "%s — cheaper via %s (cost %d). Candidate updated.\nGerald files the amendment in triplicate." % [graph_data[neighbor_id]["name"], graph_data[_active_node]["name"], int(weight)],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s — existing path (%d) still best. No update.\nConservatism wins again. As usual." % [graph_data[neighbor_id]["name"], int(_key[neighbor_id])],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	# Show the current key values for non-MST nodes
	var result: Array = []
	for node_id: String in graph_data.keys():
		if not _in_mst.has(node_id) and _key.get(node_id, INF) < INF:
			result.append("[%d] — %s" % [int(_key[node_id]), graph_data[node_id]["name"]])
	return result


func _build_mst_message(graph_data: Dictionary) -> String:
	var lines: Array = []
	var total_weight: float = 0.0
	for edge in _mst_edges:
		var from_name: String = graph_data[edge[0]]["name"]
		var to_name: String = graph_data[edge[1]]["name"]
		var cost: float = edge[2]
		total_weight += cost
		lines.append("  %s -- %s (cost %d)" % [from_name, to_name, int(cost)])
	return "Edges: %s | Total weight: %d. Stamps was last. Cost 8. Gerald judged it." % [", ".join(lines), int(total_weight)]
