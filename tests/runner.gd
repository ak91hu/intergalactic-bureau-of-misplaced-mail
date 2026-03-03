extends SceneTree

const SUITES: Array = [
	preload("res://tests/test_contract.gd"),
	preload("res://tests/test_bfs.gd"),
	preload("res://tests/test_dfs.gd"),
	preload("res://tests/test_topo_sort.gd"),
	preload("res://tests/test_dijkstra.gd"),
	preload("res://tests/test_bellman_ford.gd"),
	preload("res://tests/test_prim.gd"),
	preload("res://tests/test_astar.gd"),
	preload("res://tests/test_floyd_warshall.gd"),
	preload("res://tests/test_kruskal.gd"),
]


func _initialize() -> void:
	var total_pass: int = 0
	var total_fail: int = 0
	print("\n=== IBMM Test Suite ===\n")
	for SuiteClass in SUITES:
		var suite = SuiteClass.new()
		suite.run()
		var status: String = "OK" if suite.fail_count == 0 else "FAIL"
		print("[%s]  %-36s  %d pass  %d fail" % [status, suite.suite_name, suite.pass_count, suite.fail_count])
		total_pass += suite.pass_count
		total_fail += suite.fail_count
	print("\n--- %d pass  %d fail ---\n" % [total_pass, total_fail])
	quit(1 if total_fail > 0 else 0)
