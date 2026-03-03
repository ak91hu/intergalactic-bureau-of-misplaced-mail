extends "res://tests/suite_base.gd"

const _AlgoKruskal = preload("res://AlgorithmKruskal.gd")


func run() -> void:
	suite_name = "Kruskal MST"
	var algo := _AlgoKruskal.new()
	_run_all_steps(algo)

	# MST for 6 nodes must have exactly 5 edges
	assert_eq(algo._mst_edges.size(), 5, "Kruskal: exactly 5 MST edges (N-1)")

	# Confirmed MST weight: 1+1+2+3+4 = 11
	# (redundancy-delays:1, stamps-destination:1, forms-lost:2, redundancy-forms:3, lost-destination:4)
	var total_weight: int = 0
	for edge in algo._mst_edges:
		total_weight += edge[2]
	assert_eq(total_weight, 11, "Kruskal: MST total weight == 11")

	# All 6 nodes must appear in the MST edge endpoints
	var covered: Dictionary = {}
	for edge in algo._mst_edges:
		covered[edge[0]] = true
		covered[edge[1]] = true
	assert_eq(covered.size(), 6, "Kruskal: all 6 nodes covered by MST edges")
