extends "res://tests/suite_base.gd"

const _AlgoBF = preload("res://AlgorithmBellmanFord.gd")


func run() -> void:
	suite_name = "Bellman-Ford"
	var algo := _AlgoBF.new()
	_run_all_steps(algo)

	# Real weights: forms->lost = -2
	# Shortest path to destination: redundancy->forms->lost->destination = 3+(-2)+4 = 5
	assert_eq(algo._dist["destination"], 5, "BellmanFord: dist[destination] == 5 (real -2 edge)")
	assert_true(algo._dist["destination"] < 9, "BellmanFord: negative edge shorter than Dijkstra abs path (5 < 9)")
