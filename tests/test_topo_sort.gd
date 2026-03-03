extends "res://tests/suite_base.gd"

const _AlgoTopo = preload("res://AlgorithmTopoSort.gd")


func run() -> void:
	suite_name = "Topological Sort"
	var algo := _AlgoTopo.new()
	var steps: Array = _run_all_steps(algo)

	# Collect nodes in the order they first receive state "visited" (= dequeued order)
	var topo_order: Array = []
	var seen: Dictionary = {}
	for step in steps:
		for change in step.get("state_changes", []):
			var nid: String = change["id"]
			if change["state"] == "visited" and not seen.has(nid):
				seen[nid] = true
				topo_order.append(nid)

	assert_eq(topo_order.size(), 6, "TopoSort produces 6 visited nodes")

	var idx: Dictionary = {}
	for i: int in topo_order.size():
		idx[topo_order[i]] = i

	# Dependency constraints: prerequisite must appear at a lower index
	assert_true(idx.get("redundancy", 99) < idx.get("forms", 99),       "topo: redundancy before forms")
	assert_true(idx.get("redundancy", 99) < idx.get("delays", 99),      "topo: redundancy before delays")
	assert_true(idx.get("forms", 99)      < idx.get("stamps", 99),      "topo: forms before stamps")
	assert_true(idx.get("forms", 99)      < idx.get("lost", 99),        "topo: forms before lost")
	assert_true(idx.get("delays", 99)     < idx.get("lost", 99),        "topo: delays before lost")
	assert_true(idx.get("stamps", 99)     < idx.get("destination", 99), "topo: stamps before destination")
	assert_true(idx.get("lost", 99)       < idx.get("destination", 99), "topo: lost before destination")

	assert_true(steps[-1].get("is_complete", false), "TopoSort is_complete fires")
