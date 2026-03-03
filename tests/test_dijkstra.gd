extends "res://tests/suite_base.gd"

const _AlgoDijkstra = preload("res://AlgorithmDijkstra.gd")


func run() -> void:
	suite_name = "Dijkstra"
	var algo := _AlgoDijkstra.new()
	_run_all_steps(algo)

	# Abs weights: forms->lost = abs(-2) = 2
	# Shortest paths from redundancy:
	#   delays:      1   (direct edge)
	#   forms:       3   (direct edge)
	#   lost:        5   (redundancy->forms->lost: 3+2)
	#   destination: 9   (redundancy->forms->lost->destination: 3+2+4)
	assert_eq(algo._dist["delays"],      1.0, "Dijkstra: dist[delays] == 1")
	assert_eq(algo._dist["forms"],       3.0, "Dijkstra: dist[forms] == 3")
	assert_eq(algo._dist["lost"],        5.0, "Dijkstra: dist[lost] == 5 (abs weight used)")
	assert_eq(algo._dist["destination"], 9.0, "Dijkstra: dist[destination] == 9")
