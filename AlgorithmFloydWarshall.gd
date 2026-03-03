class_name AlgorithmFloydWarshall
extends AlgorithmBase

const INF: int = 1 << 29

var _dist: Array = []             # 2D: _dist[i][j] = shortest i->j
var _node_ids: Array = []         # ordered list matching matrix indices
var _node_index: Dictionary = {}  # node_id -> int index
var _k: int = 0
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Floyd-Warshall"


func get_structure_label() -> String:
	return ">> DISTANCES (all nodes->dest):"


func get_welcome_message() -> String:
	return "Floyd-Warshall: O(V^3) = 216 operations to find ALL shortest paths between ALL pairs. 6 passes. Real edge weights — the -2 shortcut is included. Watch redundancy->destination drop from INF to 5. Dijkstra never knew."


func initialize(graph_data: Dictionary, _start_node: String) -> Dictionary:
	_node_ids = graph_data.keys()
	_node_index = {}
	for i: int in _node_ids.size():
		_node_index[_node_ids[i]] = i
	_k = 0
	_is_complete_flag = false
	_initialized = true

	var n: int = _node_ids.size()
	_dist = []
	for i: int in n:
		var row: Array = []
		for j: int in n:
			row.append(INF)
		_dist.append(row)

	for i: int in n:
		_dist[i][i] = 0

	for from_id: String in graph_data.keys():
		var fi: int = _node_index[from_id]
		for to_id: String in graph_data[from_id]["neighbors"]:
			var ti: int = _node_index[to_id]
			_dist[fi][ti] = graph_data[from_id]["weights"].get(to_id, 0)

	return {
		"state_changes": [],
		"structure": _build_structure_display(graph_data),
		"message": "FORM FW-INF — ALL-PAIRS MATRIX INITIALIZED.\nDirect edges loaded. The -2 edge is real here. k=0..5 queued. Director Zorp is watching.",
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _k >= _node_ids.size():
		return _finalize(graph_data)

	var k_id: String = _node_ids[_k]
	var ki: int = _k
	_k += 1

	var n: int = _node_ids.size()
	var improvements: Array = []
	for i: int in n:
		if _dist[i][ki] == INF:
			continue
		for j: int in n:
			if _dist[ki][j] == INF:
				continue
			var candidate: int = _dist[i][ki] + _dist[ki][j]
			if candidate < _dist[i][j]:
				improvements.append([_node_ids[i], _node_ids[j], _dist[i][j], candidate])
				_dist[i][j] = candidate

	var msg: String
	if improvements.is_empty():
		msg = "k=%d via %s — no improvements.\n%s is not a useful relay node. It has accepted this." % [ki, graph_data[k_id]["name"], graph_data[k_id]["name"]]
	else:
		var lines: Array = []
		for imp: Array in improvements:
			var old_str: String = "INF" if imp[2] == INF else str(imp[2])
			lines.append("%s->%s: %s -> %d" % [graph_data[imp[0]]["name"], graph_data[imp[1]]["name"], old_str, imp[3]])
		msg = "k=%d via %s — %d path(s) improved.\n%s" % [ki, graph_data[k_id]["name"], improvements.size(), " | ".join(lines)]

	if _k >= _node_ids.size():
		_is_complete_flag = true
		var dest_i: int = _node_index.get("destination", -1)
		var red_i: int = _node_index.get("redundancy", -1)
		var red_dest: int = INF
		if red_i >= 0 and dest_i >= 0:
			red_dest = _dist[red_i][dest_i]
		var rd_str: String = "INF" if red_dest == INF else str(red_dest)
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": msg + "\n\nFW COMPLETE — redundancy->destination = %s (3 + -2 + 4 = 5).\nDijkstra said 9. One of them is wrong. Director Zorp knows which." % rd_str,
			"is_complete": true
		}

	return {
		"state_changes": [],
		"structure": _build_structure_display(graph_data),
		"message": msg,
		"is_complete": false
	}


func is_complete() -> bool:
	return _is_complete_flag


func _finalize(graph_data: Dictionary) -> Dictionary:
	_is_complete_flag = true
	var dest_i: int = _node_index.get("destination", -1)
	var red_i: int = _node_index.get("redundancy", -1)
	var red_dest: int = INF
	if red_i >= 0 and dest_i >= 0:
		red_dest = _dist[red_i][dest_i]
	var rd_str: String = "INF" if red_dest == INF else str(red_dest)
	return {
		"state_changes": [],
		"structure": _build_structure_display(graph_data),
		"message": "FW COMPLETE — redundancy->destination = %s credits.\n(3 + -2 + 4 = 5). Dijkstra said 9. The -2 edge changes everything." % rd_str,
		"is_complete": true
	}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	var dest_i: int = _node_index.get("destination", -1)
	if dest_i < 0:
		return result
	for node_id: String in _node_ids:
		var ni: int = _node_index[node_id]
		var d: int = _dist[ni][dest_i]
		var d_str: String = "INF" if d == INF else str(d)
		result.append("%s->dest: %s" % [node_id, d_str])
	return result
