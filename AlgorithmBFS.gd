class_name AlgorithmBFS
extends AlgorithmBase

var _visited: Dictionary = {}
var _frontier: Array[String] = []
var _active_node: String = ""
var _active_neighbor_index: int = 0
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Breadth-First Search"


func get_structure_label() -> String:
	return ">> THE QUEUE:"


func get_welcome_message() -> String:
	return "Welcome to the Intergalactic Bureau of Misplaced Mail.\n\nA package of unknown origin is somewhere in our facility. We will use Breadth-First Search to locate it — one agonizing bureaucratic step at a time.\n\nPress 'Process Next Memo' to begin."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_visited = {}
	_frontier = []
	_active_node = ""
	_active_neighbor_index = 0
	_is_complete_flag = false
	_initialized = true

	_visited[start_node] = true
	_frontier.append(start_node)

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "URGENT INTERDEPARTMENTAL MEMO\nTO: All Staff  FROM: The Algorithm\nRE: BFS Protocol Initiated\n\nA package of unknown origin has been detected at the %s. It has been added to THE QUEUE — the sacred list that governs all operations. Do not touch THE QUEUE." % graph_data[start_node]["name"],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _active_node.is_empty():
		return _dequeue_next_node(graph_data)
	else:
		return _examine_next_neighbor(graph_data)


func is_complete() -> bool:
	return _is_complete_flag


func _dequeue_next_node(graph_data: Dictionary) -> Dictionary:
	if _frontier.is_empty():
		_is_complete_flag = true
		return {
			"state_changes": [],
			"structure": [],
			"message": "BFS COMPLETE — STATUS: Satisfactory (Officially)\n\nTHE QUEUE has been fully processed. All reachable departments have been visited exactly once, as mandated by The Great Algorithm. The mail's current whereabouts remain classified. Submit Form 404 (Not Found) if you require further information.",
			"is_complete": true
		}

	_active_node = _frontier.pop_front()
	_active_neighbor_index = 0

	return {
		"state_changes": [{"id": _active_node, "state": "visited"}],
		"structure": _build_structure_display(graph_data),
		"message": "NOW PROCESSING: %s\n\nThis department has been removed from THE QUEUE and is now under active investigation. An intern has been dispatched with a flashlight and a map from 1987. All neighboring departments will be examined per Sub-Regulation 9, Clause 3(b)." % graph_data[_active_node]["name"],
		"is_complete": false
	}


func _examine_next_neighbor(graph_data: Dictionary) -> Dictionary:
	var neighbors: Array = graph_data[_active_node]["neighbors"]

	if _active_neighbor_index >= neighbors.size():
		var completed_node: String = _active_node
		_active_node = ""
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "PROCESSING COMPLETE: %s\n\nAll neighboring departments have been duly inspected, stamped, and cross-referenced. The intern has returned, mildly traumatized. Proceeding to the next item in THE QUEUE." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _visited.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "NEIGHBOR ALREADY VISITED: %s\n\nA duplicate visit request was filed, reviewed by a committee of three senior bureaucrats, found to be entirely redundant, and ceremonially shredded. We do not revisit the visited. That is Policy 7.7.7." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		_visited[neighbor_id] = true
		_frontier.append(neighbor_id)
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "NEIGHBOR DISCOVERED: %s\n\nThis department had absolutely no warning. A notice has been filed and it has been added to THE QUEUE. It must now wait its turn, along with everyone else, for an indeterminate number of business decades." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for dept_id: String in _frontier:
		result.append(graph_data[dept_id]["name"])
	return result
