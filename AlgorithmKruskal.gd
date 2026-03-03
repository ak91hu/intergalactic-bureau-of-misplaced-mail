class_name AlgorithmKruskal
extends AlgorithmBase

var _sorted_edges: Array = []    # Array of [weight: int, from_id: String, to_id: String]
var _edge_index: int = 0
var _parent: Dictionary = {}
var _rank: Dictionary = {}
var _mst_edges: Array = []       # Array of [from_id, to_id, weight]
var _pending_visited: Array = [] # Nodes to mark visited on the next step
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Kruskal's MST"


func get_structure_label() -> String:
	return ">> EDGE CANDIDATES (sorted):"


func get_welcome_message() -> String:
	return "Welcome to the Intergalactic Bureau of Misplaced Mail.\n\nKruskal's Algorithm builds a Minimum Spanning Tree by sorting ALL edges globally and greedily accepting the cheapest edge that does not create a cycle.\n\nUnion-Find with path compression tracks connected components. Compare to Prim's: same MST weight (11), different discovery order.\n\nPress 'Process Next Memo' to begin."


func initialize(graph_data: Dictionary, _start_node: String) -> Dictionary:
	_sorted_edges = []
	_edge_index = 0
	_parent = {}
	_rank = {}
	_mst_edges = []
	_pending_visited = []
	_is_complete_flag = false
	_initialized = true

	for node_id: String in graph_data.keys():
		_parent[node_id] = node_id
		_rank[node_id] = 0

	# Build undirected edge list, no duplicates, abs weights
	var seen_edges: Dictionary = {}
	for from_id: String in graph_data.keys():
		for to_id: String in graph_data[from_id]["neighbors"]:
			var weight: int = abs(graph_data[from_id]["weights"].get(to_id, 0))
			var key: String = (from_id if from_id < to_id else to_id) + "|" + (to_id if from_id < to_id else from_id)
			if not seen_edges.has(key):
				seen_edges[key] = true
				_sorted_edges.append([weight, from_id, to_id])

	_sorted_edges.sort()

	return {
		"state_changes": [],
		"structure": _build_structure_display(graph_data),
		"message": "KRUSKAL'S ALGORITHM — FORM KRU-7F\nRE: Minimum Spanning Tree (Global Sort)\n\n%d edges sorted by ascending weight (abs values).\nUnion-Find initialized — each department is its own component.\n\nGoal: accept N-1 = %d edges without creating cycles.\nTarget MST weight: 11 (same as Prim's MST)." % [_sorted_edges.size(), graph_data.size() - 1],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	# Process pending "visited" transitions from last accepted edge
	if not _pending_visited.is_empty():
		var nodes: Array = _pending_visited.duplicate()
		_pending_visited.clear()
		var sc: Array = []
		for node_id: String in nodes:
			sc.append({"id": node_id, "state": "visited"})
		if _mst_edges.size() >= graph_data.size() - 1:
			_is_complete_flag = true
			return {
				"state_changes": sc,
				"structure": [],
				"message": "MST COMPLETE — STATUS: Minimally Connected\n\n%s" % _build_mst_message(graph_data),
				"is_complete": true
			}
		return {
			"state_changes": sc,
			"structure": _build_structure_display(graph_data),
			"message": "EDGE CONFIRMED — both departments inducted into MST. %d of %d edges accepted. Total weight so far: %d." % [_mst_edges.size(), graph_data.size() - 1, _mst_weight()],
			"is_complete": false
		}

	if _mst_edges.size() >= graph_data.size() - 1:
		_is_complete_flag = true
		return {
			"state_changes": [],
			"structure": [],
			"message": "MST COMPLETE — STATUS: Minimally Connected\n\n%s" % _build_mst_message(graph_data),
			"is_complete": true
		}

	if _edge_index >= _sorted_edges.size():
		_is_complete_flag = true
		return {
			"state_changes": [],
			"structure": [],
			"message": "KRUSKAL'S COMPLETE — All edges examined.\n\n%s" % _build_mst_message(graph_data),
			"is_complete": true
		}

	var edge: Array = _sorted_edges[_edge_index]
	_edge_index += 1
	var weight: int = edge[0]
	var from_id: String = edge[1]
	var to_id: String = edge[2]

	var root_a: String = _find(from_id)
	var root_b: String = _find(to_id)

	if root_a == root_b:
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "REJECTED — CYCLE DETECTED\n\nEdge: %s <-> %s (weight: %d)\n\nBoth departments are already in the same component. Adding this edge would create a cycle. Form CYCLE-ERR filed and ceremonially shredded." % [graph_data[from_id]["name"], graph_data[to_id]["name"], weight],
			"is_complete": false,
			"examined_edge": {"from": from_id, "to": to_id}
		}
	else:
		_union(from_id, to_id)
		_mst_edges.append([from_id, to_id, weight])
		_pending_visited = [from_id, to_id]
		return {
			"state_changes": [
				{"id": from_id, "state": "frontier"},
				{"id": to_id,   "state": "frontier"}
			],
			"structure": _build_structure_display(graph_data),
			"message": "ACCEPTED — EDGE ADDED TO MST\n\nEdge: %s <-> %s (weight: %d)\n\nComponents merged. MST edge %d of %d accepted. Total MST weight so far: %d." % [graph_data[from_id]["name"], graph_data[to_id]["name"], weight, _mst_edges.size(), graph_data.size() - 1, _mst_weight()],
			"is_complete": false,
			"examined_edge": {"from": from_id, "to": to_id}
		}


func is_complete() -> bool:
	return _is_complete_flag


func _find(node_id: String) -> String:
	if _parent[node_id] != node_id:
		_parent[node_id] = _find(_parent[node_id])
	return _parent[node_id]


func _union(a: String, b: String) -> void:
	var ra: String = _find(a)
	var rb: String = _find(b)
	if ra == rb:
		return
	if _rank[ra] < _rank[rb]:
		_parent[ra] = rb
	elif _rank[ra] > _rank[rb]:
		_parent[rb] = ra
	else:
		_parent[rb] = ra
		_rank[ra] += 1


func _mst_weight() -> int:
	var total: int = 0
	for edge: Array in _mst_edges:
		total += edge[2]
	return total


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for i: int in range(_edge_index, _sorted_edges.size()):
		var edge: Array = _sorted_edges[i]
		result.append("[%d] %s | %s" % [edge[0], graph_data[edge[1]]["name"], graph_data[edge[2]]["name"]])
	return result


func _build_mst_message(graph_data: Dictionary) -> String:
	var lines: Array = []
	var total: int = 0
	for edge: Array in _mst_edges:
		lines.append("  %s <-> %s (weight: %d)" % [graph_data[edge[0]]["name"], graph_data[edge[1]]["name"], edge[2]])
		total += edge[2]
	return "MST Edges:\n%s\n\nTotal MST weight: %d\nAll 6 departments connected with minimum overhead.\nSame total as Prim's (both find the true MST), different discovery order." % ["\n".join(lines), total]
