extends "res://tests/suite_base.gd"

const Session := preload("res://CourierSession.gd")
const Levels := preload("res://CourierLevels.gd")
const Solver := preload("res://CourierSolver.gd")
const Graph := preload("res://CourierGraph.gd")

func run() -> void:
	suite_name = "Courier campaign: independent correctness"
	for algorithm: int in range(9):
		for tier: int in range(3):
			for variant: int in range(3):
				_check_mission(algorithm, tier, variant)
	_check_consequences()
	_check_negative_cycle()

func _check_mission(algorithm: int, tier: int, variant: int) -> void:
	var data: Dictionary = Levels.generate(algorithm, tier, variant)
	assert_eq(data, Levels.generate(algorithm, tier, variant), "seed reproducibly generates a level")
	var session = Session.new()
	session.setup(data)
	var graph = session.graph
	assert_eq(graph.nodes.size(), 6 + tier, "difficulty changes graph size")
	assert_true(_brute_paths(graph, "A", graph.target)["hops"] < Solver.INF, "generated target reachable")
	assert_true(not session.reference["negative_cycle"], "generated rebates have no negative cycle")
	for edge: Dictionary in graph.active_edges():
		if algorithm not in [4, 7]: assert_true(edge["weight"] > 0, "nonnegative algorithm receives positive weights")
	if tier > 0:
		var closed: int = 0
		for edge: Dictionary in graph.edges:
			if edge["closed"]: closed += 1
		assert_true(closed > 0, "advanced level has visible closed lane")
	if algorithm in [3, 4, 6, 7]:
		for from: String in graph.ids():
			for to: String in graph.ids():
				assert_eq(session.reference["distances"][from][to], _brute_paths(graph, from, to)["cost"], "matrix agrees with independently enumerated simple paths")
	if algorithm == 6:
		for id: String in graph.ids():
			assert_true(session.h[id] >= 0, "heuristic nonnegative")
			assert_true(session.h[id] <= session.reference["distances"][id][graph.target] + 0.00001, "heuristic never overestimates")
		for edge: Dictionary in graph.active_edges():
			assert_true(session.h[edge["from"]] <= edge["weight"] + session.h[edge["to"]] + 0.00001, "heuristic consistent across every lane")
	var guard: int = 0
	while session.phase != "complete" and guard < 300:
		var options: Array = session.expected_choices()
		assert_true(not options.is_empty(), "every unfinished phase offers a legal next action")
		if options.is_empty(): break
		var response: Dictionary = session.choose(options.front())
		assert_true(response.get("accepted", false), "legal learner action accepted")
		guard += 1
	assert_eq(session.phase, "complete", "all nine algorithms and three tiers complete")
	assert_eq(session.mistakes, 0, "valid reference play has no errors")
	assert_eq(session.result.get("stars", 0), 3, "correct unassisted play earns mastery")
	assert_true(guard < 100, "round is short enough for learning rather than repetitive clicking")
	if algorithm == 0:
		assert_eq(session.distances[graph.target], _brute_paths(graph, "A", graph.target)["hops"], "BFS minimizes hops")
	elif algorithm == 1:
		assert_true(graph.route_cost(Solver.predecessor_path(session.previous, "A", graph.target)) < Solver.INF, "DFS reconstructs a valid path")
	elif algorithm == 2:
		for edge: Dictionary in graph.active_edges():
			assert_true(session.order.find(edge["from"]) < session.order.find(edge["to"]), "topological order respects each prerequisite")
	elif algorithm in [3, 4, 6]:
		assert_eq(session.distances[graph.target], _brute_paths(graph, "A", graph.target)["cost"], "shortest-path algorithm gives independently verified cost")
	elif algorithm in [5, 8]:
		assert_eq(session.tree.size(), graph.nodes.size() - 1, "network has n-1 edges")
		assert_eq(session.tree_cost, _brute_tree(graph), "Prim/Kruskal equals exhaustively checked minimum tree")
	elif algorithm == 7:
		assert_eq(session.matrix, session.reference["distances"], "manual relay order yields full all-pairs solution")
		assert_eq(session.deliveries.size(), 2 if tier == 2 else 1, "advanced all-pairs lesson delivers for two sources")
	if CourierLessons.is_weighted(algorithm):
		for delivery: Dictionary in session.deliveries:
			assert_eq(graph.route_cost(delivery["route"]), delivery["cost"], "actual parcel cost equals selected lane sum")

func _brute_paths(graph, source: String, target: String) -> Dictionary:
	var best: Dictionary = {"cost": 0 if source == target else Solver.INF, "hops": 0 if source == target else Solver.INF}
	_enumerate_paths(graph, source, target, [source], 0, best)
	return best

func _enumerate_paths(graph, current: String, target: String, path: Array, cost: int, best: Dictionary) -> void:
	if current == target:
		best["cost"] = mini(best["cost"], cost)
		best["hops"] = mini(best["hops"], path.size() - 1)
		return
	for neighbor: String in graph.neighbors(current):
		if neighbor not in path:
			var extended: Array = path.duplicate()
			extended.append(neighbor)
			_enumerate_paths(graph, neighbor, target, extended, cost + int(graph.edge_between(current, neighbor)["weight"]), best)

func _brute_tree(graph) -> int:
	var edges: Array = graph.active_edges()
	var minimum: int = Solver.INF
	# Exhaustive subsets are an independent oracle, not another greedy implementation.
	for mask: int in range(1 << edges.size()):
		var chosen: int = 0
		for bit: int in edges.size():
			if mask & (1 << bit): chosen += 1
		if chosen != graph.nodes.size() - 1: continue
		var reached: Array = [graph.source]
		var total: int = 0
		for bit: int in edges.size():
			if mask & (1 << bit): total += int(edges[bit]["weight"])
		if total >= minimum: continue
		for round_index: int in graph.nodes.size():
			for bit: int in edges.size():
				if not mask & (1 << bit): continue
				var edge: Dictionary = edges[bit]
				if edge["from"] in reached and edge["to"] not in reached: reached.append(edge["to"])
				if edge["to"] in reached and edge["from"] not in reached: reached.append(edge["from"])
		if reached.size() == graph.nodes.size(): minimum = total
	return minimum

func _play_to(session, target_phase: String) -> void:
	for guard: int in range(300):
		if session.phase == target_phase: return
		var next: Array = session.expected_choices()
		if next.is_empty(): break
		session.choose(next.front())
	assert_eq(session.phase, target_phase, "requested gameplay phase reachable")

func _check_consequences() -> void:
	var session = Session.new()
	session.setup(Levels.generate(0, 0))
	session.choose("begin")
	session.choose("node:A")
	var before: Dictionary = session.distances.duplicate()
	assert_false(session.choose("node:C")["accepted"], "BFS cannot pop the wrong end of the queue")
	assert_eq(session.distances, before, "learning mistake does not corrupt the algorithm")
	assert_eq(session.mistakes, 1, "learning mistake retained in report")
	session.hint()
	session.hint()
	assert_eq(session.hints, 1, "same-step hints charged once")
	session.setup(Levels.generate(2, 0))
	session.choose("begin")
	assert_false(session.choose("node:F")["accepted"], "prerequisites prevent premature shipment")
	assert_true(session.status.contains("előfeltétel"), "blocked prerequisite is explained")
	session.setup(Levels.generate(3, 2))
	_play_to(session, "ready")
	session.choose("dispatch")
	session.choose("node:D")
	session.choose("node:H")
	assert_eq(session.phase, "failed", "expensive player route can fail the actual budget")
	assert_true(session.route_cost > session.budget(), "failure comes from actual lane costs")
	assert_true(session.undo(), "failure is recoverable by undo")
	assert_eq(session.phase, "delivery", "undo restores active delivery")
	assert_true(session.undo(), "can undo earlier route choice too")
	_play_to(session, "complete")
	assert_eq(session.deliveries.front()["cost"], session.optimal_cost(), "repaired route uses optimum")
	session.setup(Levels.generate(5, 2))
	session.choose("begin")
	session.choose("edge:A|D")
	for guard: int in range(100):
		if session.phase != "network": break
		session.choose(session.expected_choices().front())
	assert_eq(session.phase, "failed", "expensive network choice changes mission outcome")
	session.choose("replan")
	assert_eq(session.tree_cost, 0, "network retry restores construction budget")
	_play_to(session, "complete")
	assert_eq(session.result["stars"], 2, "retry succeeds with learning progress preserved")
	assert_true(Levels.generate(3, 1, 0)["edges"] != Levels.generate(3, 1, 1)["edges"], "variants alter topology/closure and costs")

func _check_negative_cycle() -> void:
	var data: Dictionary = Levels.generate(4, 0)
	data["nodes"] = data["nodes"].slice(0, 3)
	data["target"] = "C"
	data["jobs"] = [{"source": "A", "target": "C"}]
	data["edges"] = [
		{"from":"A", "to":"B", "weight":1, "closed":false, "key":"A|B"},
		{"from":"B", "to":"C", "weight":-3, "closed":false, "key":"B|C"},
		{"from":"C", "to":"B", "weight":1, "closed":false, "key":"C|B"}
	]
	for algorithm: int in [4, 7]:
		data["algorithm"] = algorithm
		var session = Session.new()
		session.setup(data)
		_play_to(session, "anomaly")
		assert_true(session.status.contains("negatív kör"), "negative cycle explained instead of reconstructing an infinite path")
		session.choose("report_cycle")
		assert_eq(session.phase, "complete", "correct anomaly report is a successful learning outcome")
