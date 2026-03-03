extends "res://tests/suite_base.gd"

const _AlgoFW = preload("res://AlgorithmFloydWarshall.gd")


func run() -> void:
	suite_name = "Floyd-Warshall"
	var algo := _AlgoFW.new()
	_run_all_steps(algo)

	# _dist is a 2D Array; use _node_index to map node_ids to matrix indices
	var ri: int = algo._node_index["redundancy"]
	var fi: int = algo._node_index["forms"]
	var li: int = algo._node_index["lost"]
	var di: int = algo._node_index["destination"]

	# redundancy->destination = 5 via the -2 shortcut (3 + (-2) + 4 = 5)
	assert_eq(algo._dist[ri][di], 5,  "FW: redundancy->destination == 5 (negative shortcut)")
	assert_eq(algo._dist[ri][fi], 3,  "FW: redundancy->forms == 3")
	assert_eq(algo._dist[fi][li], -2, "FW: forms->lost == -2 (raw negative preserved)")
