extends "res://tests/suite_base.gd"

const _AlgoBFS = preload("res://AlgorithmBFS.gd")


func run() -> void:
	suite_name = "BFS"
	var algo := _AlgoBFS.new()
	var steps: Array = _run_all_steps(algo)

	# Collect visited nodes and first-frontier step index per node
	var visited_nodes: Dictionary = {}
	var frontier_step: Dictionary = {}  # node_id -> step index of first "frontier"
	for i: int in steps.size():
		for change in steps[i].get("state_changes", []):
			var nid: String = change["id"]
			if change["state"] == "frontier" and not frontier_step.has(nid):
				frontier_step[nid] = i
			if change["state"] == "visited":
				visited_nodes[nid] = true

	# All 6 nodes visited
	assert_eq(visited_nodes.size(), 6, "BFS visits all 6 nodes")
	for node_id in _GM.DEPARTMENTS.keys():
		assert_true(visited_nodes.has(node_id), "BFS visits node: %s" % node_id)

	# Level-order invariants: parent level discovered before child level
	assert_true(
		frontier_step.get("redundancy", 9999) < frontier_step.get("forms", 9999),
		"BFS level order: redundancy before forms"
	)
	assert_true(
		frontier_step.get("redundancy", 9999) < frontier_step.get("delays", 9999),
		"BFS level order: redundancy before delays"
	)
	assert_true(
		frontier_step.get("forms", 9999) < frontier_step.get("stamps", 9999),
		"BFS level order: forms before stamps"
	)
	assert_true(
		frontier_step.get("forms", 9999) < frontier_step.get("lost", 9999),
		"BFS level order: forms before lost"
	)
	assert_true(
		frontier_step.get("stamps", 9999) < frontier_step.get("destination", 9999),
		"BFS level order: stamps before destination"
	)
	assert_true(
		frontier_step.get("lost", 9999) < frontier_step.get("destination", 9999),
		"BFS level order: lost before destination"
	)

	assert_true(steps[-1].get("is_complete", false), "BFS is_complete fires")
