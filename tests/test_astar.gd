extends "res://tests/suite_base.gd"

const _AlgoAStar = preload("res://AlgorithmAStar.gd")


func run() -> void:
	suite_name = "A* Search"
	var algo := _AlgoAStar.new()
	var steps: Array = _run_all_steps(algo)

	assert_true(steps[-1].get("is_complete", false), "A*: terminates")

	# A* uses abs weights (same as Dijkstra) so optimal cost to destination = 9
	# Internal g-score dict is named _g
	assert_eq(algo._g["destination"], 9.0, "A*: g[destination] == 9 (same as Dijkstra abs-weight path)")
