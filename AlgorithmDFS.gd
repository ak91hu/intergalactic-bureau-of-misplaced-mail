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
	return "DFS: same maze, different philosophy. Instead of spreading wide, we dive DEEP. Last-in, first-out. The youngest memo gets processed first. Seniority means nothing. THE STACK has spoken."


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
		"message": "FORM DFS-2B FILED — LIFO In Effect.\n%s placed atop THE STACK. It did not ask for this honour." % graph_data[start_node]["name"],
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
			"message": "DFS COMPLETE — Deeply Satisfactory.\nGerald needed therapy. Director Zorp needs a nap. Algorithm: completely fine.",
			"is_complete": true
		}

	var candidate: String = _stack.pop_back()

	if _visited.has(candidate):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "STALE MEMO: %s — already processed.\nTHE STACK lied. Shredded per Policy 7.7.7. THE STACK is haunted." % graph_data[candidate]["name"],
			"is_complete": false
		}

	_active_node = candidate
	_active_neighbor_index = 0
	_visited[candidate] = true

	return {
		"state_changes": [{"id": _active_node, "state": "visited"}],
		"structure": _build_structure_display(graph_data),
		"message": "DIVING INTO: %s\nGerald rappels into the void. 'No rope,' said Director Zorp. 'Budget cuts.'" % graph_data[_active_node]["name"],
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
			"message": "%s EXHAUSTED — Gerald surfaces from the abyss.\nBacktracking now. This is fine." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _visited.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s ALREADY VISITED — duplicate shredded.\nThe committee wept. Policy 7.7.7 prevails. It always prevails." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		_stack.push_back(neighbor_id)
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "%s STACKED — LIFO takes precedence over seniority.\nSenior staff are furious. The algorithm does not care." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	# Show stack from top (last pushed) to bottom
	var result: Array = []
	for i: int in range(_stack.size() - 1, -1, -1):
		result.append(graph_data[_stack[i]]["name"])
	return result
