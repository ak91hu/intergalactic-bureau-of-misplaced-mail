class_name AlgorithmTopoSort
extends AlgorithmBase

var _in_degree: Dictionary = {}
var _queue: Array[String] = []
var _topo_order: Array[String] = []
var _active_node: String = ""
var _active_neighbor_index: int = 0
var _is_complete_flag: bool = false
var _total_nodes: int = 0


func get_name() -> String:
	return "Topological Sort (Kahn's)"


func get_structure_label() -> String:
	return ">> ZERO-IN-DEGREE QUEUE:"


func get_welcome_message() -> String:
	return "No department ships until its in-box is completely empty. Kahn's Algorithm enforces this with extreme bureaucratic prejudice. Only zero-dependency depts may proceed. Everyone else waits. Indefinitely."


func initialize(graph_data: Dictionary, _start_node: String) -> Dictionary:
	_in_degree = {}
	_queue = []
	_topo_order = []
	_active_node = ""
	_active_neighbor_index = 0
	_is_complete_flag = false
	_total_nodes = graph_data.size()
	_initialized = true

	# Compute in-degrees for all nodes
	for node_id: String in graph_data.keys():
		_in_degree[node_id] = 0
	for node_id: String in graph_data.keys():
		for neighbor_id: String in graph_data[node_id]["neighbors"]:
			_in_degree[neighbor_id] += 1

	# Enqueue all nodes with in-degree 0
	var state_changes: Array = []
	for node_id: String in graph_data.keys():
		if _in_degree[node_id] == 0:
			_queue.append(node_id)
			state_changes.append({"id": node_id, "state": "frontier"})

	var in_degree_lines: PackedStringArray = []
	for node_id: String in graph_data.keys():
		in_degree_lines.append("  %s: %d incoming" % [graph_data[node_id]["name"], _in_degree[node_id]])

	return {
		"state_changes": state_changes,
		"structure": _build_structure_display(graph_data),
		"message": "FORM TOPO-7K — Dependency audit complete.\nIn-degrees computed. Current queue: %d dept(s) with zero obligations." % _queue.size(),
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _active_node.is_empty():
		return _dequeue_next_node(graph_data)
	else:
		return _decrement_neighbor(graph_data)


func is_complete() -> bool:
	return _is_complete_flag


func _dequeue_next_node(graph_data: Dictionary) -> Dictionary:
	if _queue.is_empty():
		_is_complete_flag = true
		if _topo_order.size() < _total_nodes:
			return {
				"state_changes": [],
				"structure": [],
				"message": "CYCLE DETECTED — Form ERR-999 filed.\nDept A waits for B. B waits for A. This is either a paradox or standard procedure.",
				"is_complete": true
			}
		var order_names: Array = []
		for node_id: String in _topo_order:
			order_names.append(graph_data[node_id]["name"])
		return {
			"state_changes": [],
			"structure": [],
			"message": "TOPO SORT COMPLETE — Valid ordering achieved. Unprecedented.\n%s" % " -> ".join(order_names),
			"is_complete": true
		}

	_active_node = _queue.pop_front()
	_active_neighbor_index = 0
	_topo_order.append(_active_node)

	return {
		"state_changes": [{"id": _active_node, "state": "visited"}],
		"structure": _build_structure_display(graph_data),
		"message": "CLEARED: %s — in-box empty, authorized to process.\nPaperwork cascade begins. Gerald, brace yourself." % graph_data[_active_node]["name"],
		"is_complete": false
	}


func _decrement_neighbor(graph_data: Dictionary) -> Dictionary:
	var neighbors: Array = graph_data[_active_node]["neighbors"]

	if _active_neighbor_index >= neighbors.size():
		var completed_node: String = _active_node
		_active_node = ""
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s — all outgoing dependencies notified.\nTHE QUEUE updated. Moving on." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1
	_in_degree[neighbor_id] -= 1

	var state_changes: Array = []
	var msg: String

	if _in_degree[neighbor_id] == 0:
		_queue.append(neighbor_id)
		state_changes.append({"id": neighbor_id, "state": "frontier"})
		msg = "%s UNBLOCKED — final dependency cleared! Added to queue.\nA minor miracle. Director Zorp is cautiously optimistic." % graph_data[neighbor_id]["name"]
	else:
		msg = "%s — still has %d incoming dependenc(ies). It waits.\nPatience is mandatory per Regulation 4-C, Sub-Clause 7." % [graph_data[neighbor_id]["name"], _in_degree[neighbor_id]]

	return {
		"state_changes": state_changes,
		"structure": _build_structure_display(graph_data),
		"message": msg,
		"is_complete": false,
		"examined_edge": {"from": _active_node, "to": neighbor_id}
	}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for dept_id: String in _queue:
		result.append(graph_data[dept_id]["name"])
	return result
