extends "res://tests/suite_base.gd"

const _AlgoPrim = preload("res://AlgorithmPrim.gd")


func run() -> void:
	suite_name = "Prim MST"
	var algo := _AlgoPrim.new()
	_run_all_steps(algo)

	# MST for 6 nodes must have exactly 5 edges
	assert_eq(algo._mst_edges.size(), 5, "Prim: exactly 5 MST edges (N-1)")

	# Confirmed MST weight: 1+3+2+4+1 = 11
	# (redundancy-delays:1, redundancy-forms:3, forms-lost:2, lost-destination:4, destination-stamps:1)
	var total_weight: float = 0.0
	for edge in algo._mst_edges:
		total_weight += float(edge[2])
	assert_eq(total_weight, 11.0, "Prim: MST total weight == 11")
