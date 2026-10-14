class_name CourierSolver
extends RefCounted

const INF: int = 100000000

static func all_pairs(graph: CourierGraph) -> Dictionary:
	var distances: Dictionary = {}
	var next_hop: Dictionary = {}
	for from: String in graph.ids():
		distances[from] = {}
		next_hop[from] = {}
		for to: String in graph.ids():
			distances[from][to] = 0 if from == to else INF
			next_hop[from][to] = ""
	for edge: Dictionary in graph.active_edges():
		_set_direct(distances, next_hop, edge["from"], edge["to"], edge["weight"])
		if not graph.directed:
			_set_direct(distances, next_hop, edge["to"], edge["from"], edge["weight"])
	for k: String in graph.ids():
		for i: String in graph.ids():
			for j: String in graph.ids():
				if distances[i][k] < INF and distances[k][j] < INF:
					var candidate: int = distances[i][k] + distances[k][j]
					if candidate < distances[i][j]:
						distances[i][j] = candidate
						next_hop[i][j] = next_hop[i][k]
	var negative: bool = false
	for id: String in graph.ids():
		negative = negative or distances[id][id] < 0
	return {"distances": distances, "next": next_hop, "negative_cycle": negative}

static func _set_direct(distances: Dictionary, next_hop: Dictionary, from: String, to: String, weight: int) -> void:
	if weight < distances[from][to]:
		distances[from][to] = weight
		next_hop[from][to] = to

static func matrix_path(next_hop: Dictionary, from: String, to: String) -> Array:
	if from == to:
		return [from]
	if next_hop.get(from, {}).get(to, "").is_empty():
		return []
	var path: Array = [from]
	for guard: int in range(next_hop.size() + 1):
		from = next_hop[from][to]
		if from.is_empty() or from in path:
			return []
		path.append(from)
		if from == to:
			return path
	return []

static func breadth_first(graph: CourierGraph, source: String, target: String) -> Dictionary:
	var queue: Array = [source]
	var distances: Dictionary = {source: 0}
	var previous: Dictionary = {}
	var order: Array = []
	while not queue.is_empty():
		var u: String = queue.pop_front()
		order.append(u)
		if u == target:
			break
		for v: String in graph.neighbors(u):
			if not distances.has(v):
				distances[v] = distances[u] + 1
				previous[v] = u
				queue.append(v)
	return {"distances": distances, "path": predecessor_path(previous, source, target), "order": order}

static func predecessor_path(previous: Dictionary, source: String, target: String) -> Array:
	var path: Array = [target]
	var cursor: String = target
	for guard: int in range(previous.size() + 2):
		if cursor == source:
			return path
		if not previous.has(cursor):
			return []
		cursor = previous[cursor]
		if cursor in path:
			return []
		path.push_front(cursor)
	return []

static func minimum_tree(graph: CourierGraph) -> Dictionary:
	var parent: Dictionary = {}
	for id: String in graph.ids():
		parent[id] = id
	var sorted: Array = graph.active_edges().duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["weight"] < b["weight"] if a["weight"] != b["weight"] else a["key"] < b["key"])
	var tree: Array = []
	var total: int = 0
	for edge: Dictionary in sorted:
		var a: String = root(parent, edge["from"])
		var b: String = root(parent, edge["to"])
		if a != b:
			parent[b] = a
			tree.append(edge["key"])
			total += edge["weight"]
	return {"edges": tree, "cost": total, "connected": tree.size() == graph.nodes.size() - 1}

static func root(parent: Dictionary, id: String) -> String:
	while parent[id] != id:
		id = parent[id]
	return id

static func heuristic(graph: CourierGraph, target: String) -> Dictionary:
	# Euclidean distance multiplied by the smallest cost/distance ratio is consistent.
	var factor: float = INF
	for edge: Dictionary in graph.active_edges():
		var length: float = graph.node(edge["from"])["position"].distance_to(graph.node(edge["to"])["position"])
		factor = minf(factor, float(edge["weight"]) / maxf(length, 0.0001))
	factor = maxf(0, factor)
	var values: Dictionary = {}
	for node: Dictionary in graph.nodes:
		values[node["id"]] = node["position"].distance_to(graph.node(target)["position"]) * factor
	return values
