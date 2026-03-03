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
	return "A package is missing. It was always missing. BFS will spread outward level by level until it is found — or we run out of departments. Same thing, really."


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
		"message": "FORM BFS-9A FILED — %s is Suspect #1.\nAdded to THE QUEUE. It had no say. THE QUEUE has spoken." % graph_data[start_node]["name"],
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
			"message": "BFS COMPLETE — All depts visited. Package still missing.\nDirector Zorp demands a report. Gerald is writing it with crayons.",
			"is_complete": true
		}

	_active_node = _frontier.pop_front()
	_active_neighbor_index = 0

	return {
		"state_changes": [{"id": _active_node, "state": "visited"}],
		"structure": _build_structure_display(graph_data),
		"message": "DEQUEUING: %s\nGerald dispatched. He brought the 1987 map again. We are concerned." % graph_data[_active_node]["name"],
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
			"message": "%s CLEARED — Gerald survived. Barely.\nNext item in THE QUEUE, please." % graph_data[completed_node]["name"],
			"is_complete": false
		}

	var neighbor_id: String = neighbors[_active_neighbor_index]
	_active_neighbor_index += 1

	if _visited.has(neighbor_id):
		return {
			"state_changes": [],
			"structure": _build_structure_display(graph_data),
			"message": "%s ALREADY VISITED — duplicate request shredded.\nThree committees, one conclusion: Policy 7.7.7 is eternal." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}
	else:
		_visited[neighbor_id] = true
		_frontier.append(neighbor_id)
		return {
			"state_changes": [{"id": neighbor_id, "state": "frontier"}],
			"structure": _build_structure_display(graph_data),
			"message": "%s DISCOVERED — Status: Blindsided.\nJoins THE QUEUE. Estimated wait: 3 to 400 business decades." % graph_data[neighbor_id]["name"],
			"is_complete": false,
			"examined_edge": {"from": _active_node, "to": neighbor_id}
		}


func _build_structure_display(graph_data: Dictionary) -> Array:
	var result: Array = []
	for dept_id: String in _frontier:
		result.append(graph_data[dept_id]["name"])
	return result
