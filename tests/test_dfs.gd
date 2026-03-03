extends "res://tests/suite_base.gd"

const _AlgoDFS = preload("res://AlgorithmDFS.gd")


func run() -> void:
	suite_name = "DFS"
	var algo := _AlgoDFS.new()
	var steps: Array = _run_all_steps(algo)

	var visited_nodes: Dictionary = {}
	for step in steps:
		for change in step.get("state_changes", []):
			if change["state"] == "visited":
				visited_nodes[change["id"]] = true

	assert_eq(visited_nodes.size(), 6, "DFS visits all 6 nodes")
	for node_id in _GM.DEPARTMENTS.keys():
		assert_true(visited_nodes.has(node_id), "DFS visits node: %s" % node_id)

	assert_true(steps[-1].get("is_complete", false), "DFS is_complete fires")
