class_name CourierSession
extends RefCounted

const INF: int = CourierSolver.INF
const SNAPSHOT_FIELDS: Array[String] = ["phase", "frontier", "distances", "previous", "visited", "current", "pending_edges", "pending_index", "scan_index", "pass_number", "round_changed", "order", "indegree", "tree", "tree_cost", "components", "examined", "matrix", "next_hop", "relays", "route", "route_cost", "job_index", "deliveries", "status", "logs", "last_changes", "last_calculation", "turns"]
var level: Dictionary = {}
var graph := CourierGraph.new()
var reference: Dictionary = {}
var h: Dictionary = {}
var phase: String = "briefing"
var frontier: Array = []
var distances: Dictionary = {}
var previous: Dictionary = {}
var visited: Dictionary = {}
var current: String = ""
var pending_edges: Array = []
var pending_index: int = 0
var scan_index: int = 0
var pass_number: int = 1
var round_changed: bool = false
var order: Array = []
var indegree: Dictionary = {}
var tree: Array = []
var tree_cost: int = 0
var components: Dictionary = {}
var examined: Array = []
var matrix: Dictionary = {}
var next_hop: Dictionary = {}
var relays: Array = []
var route: Array = []
var route_cost: int = 0
var job_index: int = 0
var deliveries: Array = []
var status: String = ""
var logs: Array = []
var last_changes: Array = []
var last_calculation: Dictionary = {}
var turns: int = 0
var mistakes: int = 0
var hints: int = 0
var retries: int = 0
var hinted: Dictionary = {}
var history: Array = []
var result: Dictionary = {}

func setup(data: Dictionary) -> void:
	level = data.duplicate(true)
	graph.setup(data)
	reference = CourierSolver.all_pairs(graph)
	h = CourierSolver.heuristic(graph, graph.target) if algorithm() == 6 else {}
	phase = "briefing"
	frontier = [graph.source]
	distances.clear()
	previous.clear()
	visited.clear()
	current = ""
	pending_edges.clear()
	pending_index = 0
	scan_index = 0
	pass_number = 1
	round_changed = false
	order.clear()
	indegree.clear()
	tree.clear()
	tree_cost = 0
	components.clear()
	examined.clear()
	relays.clear()
	route.clear()
	route_cost = 0
	job_index = 0
	deliveries.clear()
	logs.clear()
	last_changes.clear()
	last_calculation.clear()
	turns = 0
	mistakes = 0
	hints = 0
	retries = 0
	hinted.clear()
	history.clear()
	result.clear()
	for id: String in graph.ids():
		distances[id] = 0 if id == graph.source else INF
		indegree[id] = 0
		components[id] = id
	for edge: Dictionary in graph.active_edges():
		indegree[edge["to"]] += 1
	_initialize_matrix()
	status = CourierLessons.OBJECTIVES[algorithm()]

func algorithm() -> int:
	return level["algorithm"]

func choices() -> Array:
	var options: Array = []
	match phase:
		"briefing": options.append(_option("begin", "Induljon a küldetés", "Megtanulom a szabályt, aztán hálózatot építek." if CourierLessons.is_network(algorithm()) else ("Megtanulom és követem az előfeltételeket." if algorithm() == 2 else "Megtanulom a szabályt, aztán kézbesítek.")))
		"search":
			for id: String in frontier:
				var detail: String = "mélység: %d" % distances[id]
				if algorithm() == 3:
					detail = "d = %d kredit" % distances[id]
				elif algorithm() == 6:
					detail = "g=%d  h=%.1f  f=%.1f" % [distances[id], h[id], distances[id] + h[id]]
				options.append(_option("node:" + id, id + " állomás", detail))
		"edge_check", "relax":
			var calc: Dictionary = calculation()
			options.append(_option("improve", "Javítom a távolságot", "új: " + number(calc["candidate"])))
			options.append(_option("keep", "Megtartom a régit", "eddig: " + number(calc["old"])))
		"pass_end":
			options.append(_option("next_pass", "Új ellenőrzőkör" if round_changed else "Megállok: nincs javulás", "%d. teljes kör vége" % pass_number))
		"order":
			for id: String in graph.ids():
				if id not in order:
					options.append(_option("node:" + id, id + " állomás", "%d előfeltétel vár" % indegree[id]))
		"network":
			for edge: Dictionary in graph.active_edges():
				if edge["key"] in examined:
					continue
				if algorithm() == 5 and not _crosses_tree(edge):
					continue
				options.append(_option("edge:" + edge["key"], edge["from"] + " — " + edge["to"], "%d kredit" % edge["weight"]))
			options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var ea: Dictionary = graph.edge_by_key(a["id"].trim_prefix("edge:"))
				var eb: Dictionary = graph.edge_by_key(b["id"].trim_prefix("edge:"))
				return ea["weight"] < eb["weight"] if ea["weight"] != eb["weight"] else ea["key"] < eb["key"])
		"matrix":
			for id: String in graph.ids():
				if id not in relays:
					options.append(_option("node:" + id, "Köztes pont: " + id, "frissít minden párt"))
		"ready": options.append(_option("dispatch", "Átveszem a csomagot", "Most én választom meg az útvonalat."))
		"delivery":
			for id: String in graph.neighbors(route.back()):
				if id in route:
					continue
				var edge: Dictionary = graph.edge_between(route.back(), id)
				options.append(_option("node:" + id, "Tovább: " + id, "%+d kredit / +1 ugrás" % edge["weight"]))
		"next_package": options.append(_option("dispatch", "Következő csomag", "Új feladóhoz a mátrix másik sorát használom."))
		"anomaly": options.append(_option("report_cycle", "Jelentem a negatív kört", "Nincs véges minimum: a kézbesítést felfüggesztem."))
		"failed": options.append(_option("replan", "Újratervezem", "A kiszámított távolságok megmaradnak."))
	return options

func _option(id: String, label: String, detail: String) -> Dictionary:
	return {"id": id, "label": label, "detail": detail}

func expected_choices() -> Array:
	match phase:
		"search":
			if frontier.is_empty(): return []
			if algorithm() == 0: return ["node:" + str(frontier.front())]
			if algorithm() == 1: return ["node:" + str(frontier.back())]
			var best: float = INF
			var options: Array = []
			for id: String in frontier:
				var priority: float = distances[id] + (h[id] if algorithm() == 6 else 0)
				if priority < best - 0.00001:
					best = priority
					options.clear()
				if absf(priority - best) < 0.00001: options.append("node:" + id)
			return options
		"edge_check", "relax": return ["improve" if calculation()["improves"] else "keep"]
		"order":
			var ready: Array = []
			for id: String in graph.ids():
				if id not in order and indegree[id] == 0: ready.append("node:" + id)
			return ready
		"network":
			var candidates: Array = choices()
			if candidates.is_empty(): return []
			var cheapest: int = graph.edge_by_key(candidates.front()["id"].trim_prefix("edge:"))["weight"]
			var best_edges: Array = []
			for option: Dictionary in candidates:
				if graph.edge_by_key(option["id"].trim_prefix("edge:"))["weight"] == cheapest:
					best_edges.append(option["id"])
			return best_edges
		"delivery":
			var optimum: Array = optimal_route()
			var current_node: String = route.back()
			if algorithm() == 1 and current_node in optimum:
				var index: int = optimum.find(current_node)
				if index + 1 < optimum.size(): return ["node:" + str(optimum[index + 1])]
			var remaining: Dictionary = CourierSolver.breadth_first(graph, current_node, target()) if algorithm() in [0, 1] else {}
			if algorithm() in [0, 1]:
				optimum = remaining["path"]
			else:
				optimum = CourierSolver.matrix_path(reference["next"], current_node, target())
			return ["node:" + str(optimum[1])] if optimum.size() > 1 else []
		_:
			var options: Array = []
			for option: Dictionary in choices(): options.append(option["id"])
			return options

func choose(choice: String) -> Dictionary:
	var offered: bool = false
	for option: Dictionary in choices(): offered = offered or option["id"] == choice
	if not offered:
		return {"accepted": false, "message": "Ez a lépés most nem választható."}
	if phase in ["search", "edge_check", "relax", "order"] and choice not in expected_choices():
		mistakes += 1
		var explanation: String = _mistake_explanation(choice)
		_note(explanation)
		return {"accepted": false, "message": explanation, "mistake": true}
	history.append(_snapshot())
	last_changes.clear()
	turns += 1
	var event: Dictionary = {"accepted": true}
	match phase:
		"briefing": _begin()
		"search": _visit(choice.trim_prefix("node:"))
		"edge_check", "relax": _relax(choice == "improve")
		"pass_end": _end_pass()
		"order":
			var id: String = choice.trim_prefix("node:")
			var from: String = current if not current.is_empty() else graph.source
			_order_node(id)
			event["move_from"] = from
			event["move_to"] = id
		"network": _network_edge(choice.trim_prefix("edge:"))
		"matrix": _relay(choice.trim_prefix("node:"))
		"ready", "next_package": _start_delivery()
		"delivery":
			var id: String = choice.trim_prefix("node:")
			event["move_from"] = route.back()
			event["move_to"] = id
			_deliver_to(id)
		"anomaly":
			_note("Negatív kör jelentve. A kör ismétlésével a költség újra csökkenne, ezért nem létezik véges legrövidebb út.")
			_finish_mission(true)
		"failed": replan()
	event["message"] = status
	return event

func _begin() -> void:
	match algorithm():
		0, 1, 3, 6: phase = "search"
		2: phase = "order"
		4: phase = "relax"
		5, 8:
			phase = "network"
			visited[graph.source] = true if algorithm() == 5 else false
		7: phase = "matrix"
	_note("%s\n%s" % [CourierLessons.RULES[algorithm()], level["hazard"]])

func _visit(id: String) -> void:
	frontier.erase(id)
	visited[id] = true
	current = id
	if id == graph.target:
		_finish_learning()
		return
	if algorithm() in [0, 1]:
		var neighbors: Array = graph.neighbors(id)
		if algorithm() == 1: neighbors.reverse()
		var discovered: Array = []
		for v: String in neighbors:
			if distances[v] == INF:
				distances[v] = distances[id] + 1
				previous[v] = id
				frontier.append(v)
				discovered.append(v)
		_note("%s feldolgozva. Új állomások: %s. %s" % [id, ", ".join(discovered) if not discovered.is_empty() else "nincs", "A sor eleje jön." if algorithm() == 0 else "A verem teteje jön."])
	else:
		pending_edges = graph.outgoing(id)
		pending_edges = pending_edges.filter(func(edge: Dictionary) -> bool: return not visited.has(edge["to"]))
		pending_index = 0
		phase = "edge_check" if not pending_edges.is_empty() else "search"
		_note("%s véglegesítve: %d kredit. Most ellenőrizzük a kifelé vezető éleket." % [id, distances[id]])
	if frontier.is_empty() and phase == "search":
		phase = "failed"
		_note("A címzett nem érhető el ezen a hálózaton. Vizsgáld meg a lezárt és az egyirányú sávokat.")

func calculation() -> Dictionary:
	var edge: Dictionary = graph.active_edges()[scan_index] if phase == "relax" else pending_edges[pending_index]
	var from_distance: int = distances[edge["from"]]
	var candidate: int = INF if from_distance == INF else from_distance + int(edge["weight"])
	var old: int = distances[edge["to"]]
	return {"from": edge["from"], "to": edge["to"], "key": edge["key"], "weight": edge["weight"], "source": from_distance, "candidate": candidate, "old": old, "improves": candidate < old}

func _relax(improve: bool) -> void:
	var calc: Dictionary = calculation()
	last_calculation = calc.duplicate()
	if improve:
		distances[calc["to"]] = calc["candidate"]
		previous[calc["to"]] = calc["from"]
		last_changes.append({"from": calc["from"], "to": calc["to"], "old": calc["old"], "new": calc["candidate"]})
		if phase == "edge_check" and calc["to"] not in frontier: frontier.append(calc["to"])
		round_changed = true
	_note("%s → %s: %s + (%d) = %s. %s" % [calc["from"], calc["to"], number(calc["source"]), calc["weight"], number(calc["candidate"]), "Javít: " + number(calc["old"]) + " → " + number(calc["candidate"]) if improve else "Nem kisebb a réginél; megtartjuk."])
	if phase == "relax":
		scan_index += 1
		if scan_index >= graph.active_edges().size(): phase = "pass_end"
	else:
		pending_index += 1
		if pending_index >= pending_edges.size(): phase = "search"

func _end_pass() -> void:
	if not round_changed or pass_number >= graph.nodes.size() - 1:
		for edge: Dictionary in graph.active_edges():
			if distances[edge["from"]] < INF and distances[edge["from"]] + edge["weight"] < distances[edge["to"]]:
				phase = "anomaly"
				_note("%d kör után még javulna a %s él. Elérhető negatív kör van: nincs véges minimum." % [pass_number, edge["key"].replace("|", " → ")])
				return
		_finish_learning()
		status = "Nincs további javítás: %d teljes kör után megállhatunk. " % pass_number + status
		return
	pass_number += 1
	scan_index = 0
	round_changed = false
	phase = "relax"
	_note("Kezdődik a %d. kör. Egy teljes, változás nélküli kör bizonyítja a megállást." % pass_number)

func _order_node(id: String) -> void:
	order.append(id)
	visited[id] = true
	current = id
	for neighbor: String in graph.neighbors(id): indegree[neighbor] -= 1
	_note("%s előfeltételei elkészültek, ezért feladható. Sorrend: %s." % [id, " → ".join(order)])
	if order.size() == graph.nodes.size():
		_note("Minden állomás elkészült: a csomagok szabályos sorrendben átadva. " + CourierLessons.TAKEAWAYS[2])
		_finish_mission(true)

func _crosses_tree(edge: Dictionary) -> bool:
	return (visited.get(edge["from"], false) and not visited.get(edge["to"], false)) or (visited.get(edge["to"], false) and not visited.get(edge["from"], false))

func _network_edge(key: String) -> void:
	var edge: Dictionary = graph.edge_by_key(key)
	var best: Array = expected_choices()
	var greedy: bool = "edge:" + key in best
	if not greedy: mistakes += 1
	examined.append(key)
	var a: String = CourierSolver.root(components, edge["from"])
	var b: String = CourierSolver.root(components, edge["to"])
	if a == b:
		_note("%s körbe zárna: mindkét végpont a %s komponens része. Kihagyjuk, nem költünk rá." % [key.replace("|", " — "), a])
		return
	components[b] = a
	tree.append(key)
	tree_cost += edge["weight"]
	visited[edge["from"]] = true
	visited[edge["to"]] = true
	_note("%s bekötve: +%d kredit, összesen %d. %s" % [key.replace("|", " — "), edge["weight"], tree_cost, "Ez egy legolcsóbb választható él." if greedy else "Drágább élt választottál a greedy minimumnál. A teljes keretet is figyeld!"])
	if tree.size() == graph.nodes.size() - 1:
		var optimum: int = CourierSolver.minimum_tree(graph)["cost"]
		if tree_cost > budget():
			phase = "failed"
			_note("A hálózat összefügg és körmentes, de túllépi a keretet: %d / %d kredit. A minimum %d. Lépj vissza, és cserélj drágább kapcsolatot." % [tree_cost, budget(), optimum])
		else:
			_note("A hálózat kézbesítésre kész! Költség: %d; minimum: %d. %s" % [tree_cost, optimum, CourierLessons.TAKEAWAYS[algorithm()]])
			_finish_mission(tree_cost == optimum)

func _initialize_matrix() -> void:
	matrix.clear()
	next_hop.clear()
	for from: String in graph.ids():
		matrix[from] = {}
		next_hop[from] = {}
		for to: String in graph.ids():
			matrix[from][to] = 0 if from == to else INF
			next_hop[from][to] = ""
	for edge: Dictionary in graph.active_edges():
		matrix[edge["from"]][edge["to"]] = edge["weight"]
		next_hop[edge["from"]][edge["to"]] = edge["to"]
		if not graph.directed:
			matrix[edge["to"]][edge["from"]] = edge["weight"]
			next_hop[edge["to"]][edge["from"]] = edge["from"]

func _relay(k: String) -> void:
	relays.append(k)
	visited[k] = true
	for i: String in graph.ids():
		for j: String in graph.ids():
			if matrix[i][k] >= INF or matrix[k][j] >= INF: continue
			var candidate: int = matrix[i][k] + matrix[k][j]
			if candidate < matrix[i][j]:
				last_changes.append({"from": i, "to": j, "old": matrix[i][j], "new": candidate})
				matrix[i][j] = candidate
				next_hop[i][j] = next_hop[i][k]
	_note("Köztes pont: %s. %d távolság javult. Példa: %s" % [k, last_changes.size(), _change_example(k)])
	if relays.size() == graph.nodes.size():
		for id: String in graph.ids():
			if matrix[id][id] < 0:
				phase = "anomaly"
				_note("d[%s,%s] = %d < 0: negatív kör van. A mátrix átlója mutatja a problémát." % [id, id, matrix[id][id]])
				return
		_finish_learning()

func _change_example(k: String) -> String:
	if last_changes.is_empty(): return "ezzel a köztes ponttal nem találtunk olcsóbb utat."
	var change: Dictionary = last_changes.front()
	return "d[%s,%s]: %s → %s, %s-n át." % [change["from"], change["to"], number(change["old"]), number(change["new"]), k]

func _finish_learning() -> void:
	phase = "ready"
	var path: Array = optimal_route()
	if level["guided"]:
		_note("Elkészült a terv. Ajánlott út: %s. Most a térképen TE irányítod a csomagot; más utat is választhatsz." % " → ".join(path))
	else:
		_note("Elkészült a terv. Az elődökből, illetve a mátrixból rekonstruáld az útvonalat! A kézbesítésnél TE választasz; a keret valóban számít.")

func _start_delivery() -> void:
	phase = "delivery"
	route = [source()]
	route_cost = 0
	_note("%s → %s: %d %s a keret. Kattints egy elérhető szomszédra. A nyilak irányát és a lezárást is figyeld." % [source(), target(), budget(), unit()])

func _deliver_to(id: String) -> void:
	var edge: Dictionary = graph.edge_between(route.back(), id)
	route_cost += 1 if algorithm() in [0, 1] else int(edge["weight"])
	route.append(id)
	_note("A csomag %s állomásra ért. Út: %s. Elszámolás: %d / %d %s." % [id, " → ".join(route), route_cost, budget(), unit()])
	if id == target():
		if route_cost > budget():
			phase = "failed"
			_note("Célba értél, de a keret túllépve: %d / %d %s. A jó terv %d. Lépj vissza, vagy tervezd újra az útvonalat." % [route_cost, budget(), unit(), optimal_cost()])
			return
		deliveries.append({"route": route.duplicate(), "cost": route_cost, "optimum": optimal_cost(), "source": source(), "target": target()})
		if job_index + 1 < level["jobs"].size():
			job_index += 1
			phase = "next_package"
			_note("Első csomag átadva! A következő feladó %s, címzett %s. A mátrixból ezt a másik párt is kiolvashatod." % [source(), target()])
		else:
			var optimal: bool = true
			for delivery: Dictionary in deliveries:
				optimal = optimal and (delivery["cost"] == delivery["optimum"] or algorithm() == 1)
			_note("Sikeres kézbesítés! " + CourierLessons.TAKEAWAYS[algorithm()])
			_finish_mission(optimal)
	elif choices().is_empty():
		phase = "failed"
		_note("Zsákutcába értél. Innen nem vezet járható sáv a címzetthez. A DFS-ben a visszalépés különösen fontos.")

func _finish_mission(optimal: bool) -> void:
	phase = "complete"
	var grade: int = 3 if optimal and mistakes == 0 and hints == 0 and retries == 0 else (2 if mistakes <= maxi(1, turns / 4) and optimal else 1)
	result = {"stars": grade, "score": maxi(100, 1000 - mistakes * 35 - hints * 25 - retries * 30 - (0 if optimal else 100)), "optimal": optimal, "mistakes": mistakes, "hints": hints, "turns": turns, "takeaway": CourierLessons.TAKEAWAYS[algorithm()], "deliveries": deliveries.duplicate(true), "tree_cost": tree_cost, "tree_minimum": CourierSolver.minimum_tree(graph)["cost"] if CourierLessons.is_network(algorithm()) else 0}

func source() -> String:
	return level["jobs"][job_index]["source"]

func target() -> String:
	return level["jobs"][job_index]["target"]

func optimal_route() -> Array:
	if algorithm() == 1:
		var dfs_path: Array = CourierSolver.predecessor_path(previous, source(), target())
		if not dfs_path.is_empty(): return dfs_path
	if algorithm() == 0: return CourierSolver.breadth_first(graph, source(), target())["path"]
	return CourierSolver.matrix_path(reference["next"], source(), target())

func optimal_cost() -> int:
	if CourierLessons.is_network(algorithm()): return CourierSolver.minimum_tree(graph)["cost"]
	if algorithm() in [0, 1]: return CourierSolver.breadth_first(graph, source(), target())["distances"].get(target(), INF)
	return reference["distances"][source()][target()]

func budget() -> int:
	if algorithm() == 1: return graph.nodes.size() + 2
	return optimal_cost() + [2 if not CourierLessons.is_network(algorithm()) else 4, 1, 0][level["tier"]]

func unit() -> String:
	return "ugrás" if algorithm() in [0, 1] else "kredit"

func undo() -> bool:
	if history.is_empty() or phase == "complete": return false
	var snapshot: Dictionary = history.pop_back()
	for field: String in SNAPSHOT_FIELDS: set(field, snapshot[field])
	_note("Visszaléptél. A korábbi terv és költség visszaállt; a tanulási napló hibaszáma megmarad.")
	return true

func replan() -> void:
	retries += 1
	if CourierLessons.is_network(algorithm()):
		tree.clear()
		tree_cost = 0
		examined.clear()
		visited.clear()
		for id: String in graph.ids(): components[id] = id
		if algorithm() == 5: visited[graph.source] = true
		phase = "network"
	elif algorithm() == 2:
		return
	else:
		phase = "ready"
		route.clear()
		route_cost = 0
	_note("Újratervezés: a kreditkeret visszaállt. A már megtanult távolságok megmaradnak.")

func hint() -> String:
	var fingerprint: String = "%s:%d" % [phase, turns]
	if not hinted.has(fingerprint):
		hinted[fingerprint] = true
		hints += 1
	var expected: Array = expected_choices()
	var recommendation: String = ", ".join(expected).replace("node:", "").replace("edge:", "").replace("|", "—")
	var text: String = CourierLessons.RULES[algorithm()]
	if phase == "delivery": text = "Nézd az elődökből kapott útvonalat vagy a mátrixot. Innen ajánlott következő állomás: " + recommendation + "."
	elif phase in ["edge_check", "relax"]:
		var calc: Dictionary = calculation()
		text = "%s + (%d) = %s; a régi %s. %s" % [number(calc["source"]), calc["weight"], number(calc["candidate"]), number(calc["old"]), "Javítás kell." if calc["improves"] else "Nem kisebb: megtartás kell."]
	elif not recommendation.is_empty(): text += " Most szabályos választás: " + recommendation + "."
	_note(text)
	return text

func _mistake_explanation(choice: String) -> String:
	if phase == "order":
		var id: String = choice.trim_prefix("node:")
		var blockers: Array = []
		for edge: Dictionary in graph.active_edges():
			if edge["to"] == id and edge["from"] not in order: blockers.append(edge["from"])
		return "%s még nem kész: %s előfeltétel hiányzik. Nem módosítottuk a sorrendet; próbáld újra." % [id, ", ".join(blockers)]
	if phase in ["edge_check", "relax"]:
		var calc: Dictionary = calculation()
		return "%s + (%d) = %s, a régi %s. %s Próbáld újra; a távolságok változatlanok." % [number(calc["source"]), calc["weight"], number(calc["candidate"]), number(calc["old"]), "Ez kisebb, ezért javítani kell." if calc["improves"] else "Ez nem kisebb, ezért a régit tartjuk meg."]
	return "%s A helyes jelöltek: %s. A frontiert nem módosítottuk." % [CourierLessons.RULES[algorithm()], ", ".join(expected_choices()).replace("node:", "")]

func _snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for field: String in SNAPSHOT_FIELDS:
		var value: Variant = get(field)
		snapshot[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return snapshot

func _note(message: String) -> void:
	status = message
	logs.append(message)
	if logs.size() > 60: logs.pop_front()

func code_line() -> int:
	match phase:
		"briefing": return 0
		"search": return 1
		"edge_check": return 2
		"relax": return 2
		"pass_end": return 4
		"order": return 1
		"network": return 2 if algorithm() == 5 else 1
		"matrix": return 1
		_: return CourierLessons.PSEUDOCODE[algorithm()].size() - 1

static func number(value: Variant) -> String:
	return "∞" if value >= INF else str(value)
