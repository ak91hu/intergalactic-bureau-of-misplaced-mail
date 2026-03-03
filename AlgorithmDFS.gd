class_name AlgorithmDFS
extends AlgorithmBase

var _visited: Dictionary = {}
var _stack: Array[String] = []
var _active_node: String = ""
var _active_neighbor_index: int = 0
var _is_complete_flag: bool = false


func get_name() -> String:
	return "Depth-First Search"


func get_structure_label() -> String:
	return ">> THE STACK:"


func get_welcome_message() -> String:
	return "Welcome to the Intergalactic Bureau of Misplaced Mail.\n\nInstead of the orderly queue system, DFS uses a STACK — a precarious pile of memos, processed last-in-first-out, plunging into each corridor as deep as possible before backtracking.\n\nPress 'Process Next Memo' to begin."


func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
	_visited = {}
	_stack = []
	_active_node = ""
	_active_neighbor_index = 0
	_is_complete_flag = false
	_initialized = true

	_stack.push_back(start_node)

	return {
		"state_changes": [{"id": start_node, "state": "frontier"}],
		"structure": _build_structure_display(graph_data),
		"message": "URGENT INTERDEPARTMENTAL MEMO\nTO: All Staff  FROM: The Algorithm\nRE: DFS Protocol Initiated\n\nA package of unknown origin has been detected at the %s. It has been placed atop THE STACK. Unlike THE QUEUE, THE STACK rewards those who arrived last. Seniority means nothing here." % graph_data[start_node]["name"],
		"is_complete": false
	}


func advance(graph_data: Dictionary) -> Dictionary:
	if _active_node.is_empty():
		return _pop_next_node(graph_data)
	else:
		return _examine_next_neighbor(graph_data)


func is_complete() -> bool:
	return _is_complete_flag


func _pop_next_node(graph_data: Dictionary) -> Dictionary:
	if _stack.is_empty():
		_is_complete_flag = true
		return {
			"state_changes": [],
			"structure": [],
			"message": "DFS COMPLETE — STATUS: Deeply Satisfactory\n\nTHE STACK has been exhausted. All reachable departments have been plumbed to their depths and reluctantly returned from. The intern needed a map. The map was wrong. They persevered anyway.",
			"is_complete": true
		}

	var candidate: String = _stack.pop_back()

	if _visited.has(candidate):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "STALE MEMO INTERCEPTED: %s\n\nThis memo was already filed when it reached the top of THE STACK. It has been ceremonially shredded per Policy 7.7.7. THE STACK giveth, and THE STACK taketh away." % graph_data[candidate]["name"],
			"is_complete": false
		}

	_active_node = candidate
	_active_neighbor_index = 0
	_visited[candidate] = true

	return {
		"state_changes": [{"id": _active_node, "state": "visited"}],
		"structure": _build_structure_display(graph_data),
		"message": "NOW PROCESSING: %s\n\nThis department has been removed from THE STACK and is now under active investigation. We are going DEEP before we go WIDE. Neighbors will be stacked for later. The intern has been dispatched into the corridor with a flashlight." % graph_data[_active_node]["name"],
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
			"message": "PROCESSING COMPLETE: %s\n\nAll neighbors have been discovered and added to THE STACK. The intern emerges. We now backtrack to continue from whatever is atop THE STACK. This is the DFS way." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _visited.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "NEIGHBOR ALREADY VISITED: %s\n\nA duplicate stack request was filed. Three sub-committees convened. All agreed: we do not revisit the visited. The memo was shredded. Policy 7.7.7 stands eternal." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		_stack.push_back(neighbor_id)
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "NEIGHBOR STACKED: %s\n\nThis department has been placed atop THE STACK. It will be processed before its predecessors, owing to the deeply unfair but algorithmically mandated LIFO policy. It did not ask for this." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	# Show stack from top (last pushed) to bottom
	var result: Array = []
	for i: int in range(_stack.size() - 1, -1, -1):
		result.append(graph_data[_stack[i]]["name"])
	return result
