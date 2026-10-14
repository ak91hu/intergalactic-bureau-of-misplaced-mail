class_name GraphManager
extends Node

signal node_state_changed(node_id: String, new_state: String)
signal queue_updated(display_names: Array)
signal step_message_changed(message: String)
signal algorithm_complete
signal edge_examined(from_id: String, to_id: String)
signal frame_changed(frame: Dictionary, step: int, total: int)

enum AlgorithmType { BFS, DFS, TOPO_SORT, DIJKSTRA, BELLMAN_FORD, PRIM, A_STAR, FLOYD_WARSHALL, KRUSKAL }

const DEPARTMENTS: Dictionary = {
	"redundancy": {
		"name": "Dept. of Redundancy Dept.",
		"neighbors": ["forms", "delays"],
		"weights": {"forms": 3, "delays": 1}
	},
	"forms": {
		"name": "Bureau of Unnecessary Forms",
		"neighbors": ["stamps", "lost"],
		"weights": {"stamps": 8, "lost": -2}
	},
	"delays": {
		"name": "Office of Perpetual Delays",
		"neighbors": ["lost"],
		"weights": {"lost": 6}
	},
	"stamps": {
		"name": "Division of Rubber Stamps",
		"neighbors": ["destination"],
		"weights": {"destination": 1}
	},
	"lost": {
		"name": "Archives of Misplaced Items",
		"neighbors": ["destination"],
		"weights": {"destination": 4}
	},
	"destination": {
		"name": "Actual Mail Delivery*",
		"neighbors": [],
		"weights": {}
	}
}

const START_NODE: String = "redundancy"

const ALGORITHM_SCRIPTS: Array = [
	preload("res://AlgorithmBFS.gd"),
	preload("res://AlgorithmDFS.gd"),
	preload("res://AlgorithmTopoSort.gd"),
	preload("res://AlgorithmDijkstra.gd"),
	preload("res://AlgorithmBellmanFord.gd"),
	preload("res://AlgorithmPrim.gd"),
	preload("res://AlgorithmAStar.gd"),
	preload("res://AlgorithmFloydWarshall.gd"),
	preload("res://AlgorithmKruskal.gd"),
]

var _active_algorithm: AlgorithmBase = null
var _current_type: int = AlgorithmType.BFS
var timeline: Array = []
var cursor: int = -1


func _ready() -> void:
	set_algorithm(AlgorithmType.BFS)


func get_department_name(dept_id: String) -> String:
	return DEPARTMENTS[dept_id]["name"]


func get_all_department_ids() -> Array:
	return DEPARTMENTS.keys()


func get_neighbors_of(dept_id: String) -> Array:
	return DEPARTMENTS[dept_id]["neighbors"]


func get_edge_weight(from_id: String, to_id: String) -> int:
	if DEPARTMENTS.has(from_id) and DEPARTMENTS[from_id]["weights"].has(to_id):
		return DEPARTMENTS[from_id]["weights"][to_id]
	return 0


func get_active_algorithm_welcome() -> String:
	if _active_algorithm:
		return _active_algorithm.get_welcome_message()
	return ""


func set_algorithm(type: int) -> void:
	_current_type = clampi(type, 0, ALGORITHM_SCRIPTS.size() - 1)
	_active_algorithm = ALGORITHM_SCRIPTS[_current_type].new()
	timeline.clear()
	cursor = -1
	var states: Dictionary = {}
	for id: String in DEPARTMENTS:
		states[id] = "default"
	var result: Dictionary = _active_algorithm.initialize(DEPARTMENTS, START_NODE)
	for guard: int in range(2000):
		var frame: Dictionary = result.duplicate(true)
		for change: Dictionary in frame["state_changes"]:
			states[change["id"]] = change["state"]
		frame["states"] = states.duplicate()
		timeline.append(frame)
		if result["is_complete"]:
			frame["solution_edges"] = _solution_edges()
			return
		result = _active_algorithm.advance(DEPARTMENTS)
	push_error("Algorithm exceeded the timeline step limit")


func reset_algorithm() -> void:
	set_algorithm(_current_type)


func advance_algorithm() -> void:
	if cursor + 1 >= timeline.size():
		return
	cursor += 1
	_process_step_result(timeline[cursor])
	frame_changed.emit(timeline[cursor], cursor + 1, timeline.size())

func rewind_algorithm() -> void:
	if cursor <= 0:
		return
	cursor -= 1
	_process_step_result(timeline[cursor])
	frame_changed.emit(timeline[cursor], cursor + 1, timeline.size())

func _solution_edges() -> Array:
	var edges: Array = []
	if _current_type in [AlgorithmType.PRIM, AlgorithmType.KRUSKAL]:
		for edge: Array in _active_algorithm.get("_mst_edges"):
			edges.append(edge[0] + "|" + edge[1])
	elif _current_type in [AlgorithmType.DIJKSTRA, AlgorithmType.BELLMAN_FORD, AlgorithmType.A_STAR, AlgorithmType.FLOYD_WARSHALL]:
		edges = ["redundancy|forms", "forms|lost", "lost|destination"]
	return edges


func _process_step_result(result: Dictionary) -> void:
	var state_changes: Array = result.get("state_changes", [])
	for change in state_changes:
		node_state_changed.emit(change["id"], change["state"])

	queue_updated.emit(result.get("structure", []))
	step_message_changed.emit(result.get("message", ""))

	if result.has("examined_edge"):
		var ee: Dictionary = result.get("examined_edge", {})
		edge_examined.emit(ee.get("from", ""), ee.get("to", ""))

	if result.get("is_complete", false):
		algorithm_complete.emit()
