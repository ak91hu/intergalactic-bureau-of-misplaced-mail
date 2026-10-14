class_name CourierGraph
extends RefCounted

var nodes: Array = []
var edges: Array = []
var directed: bool = true
var source: String = "A"
var target: String = "F"

func setup(data: Dictionary) -> void:
	nodes = data["nodes"].duplicate(true)
	edges = data["edges"].duplicate(true)
	directed = data.get("directed", true)
	source = data.get("source", "A")
	target = data.get("target", "F")

func ids() -> Array:
	var result: Array = []
	for node: Dictionary in nodes:
		result.append(node["id"])
	return result

func node(id: String) -> Dictionary:
	for item: Dictionary in nodes:
		if item["id"] == id:
			return item
	return {}

func active_edges() -> Array:
	var result: Array = []
	for edge: Dictionary in edges:
		if not edge.get("closed", false):
			result.append(edge)
	return result

func neighbors(id: String) -> Array:
	var result: Array = []
	for edge: Dictionary in active_edges():
		if edge["from"] == id:
			result.append(edge["to"])
		elif not directed and edge["to"] == id:
			result.append(edge["from"])
	result.sort()
	return result

func edge_between(from: String, to: String, include_closed: bool = false) -> Dictionary:
	for edge: Dictionary in edges:
		if not include_closed and edge.get("closed", false):
			continue
		if (edge["from"] == from and edge["to"] == to) or (not directed and edge["to"] == from and edge["from"] == to):
			return edge
	return {}

func edge_by_key(key: String) -> Dictionary:
	for edge: Dictionary in edges:
		if edge["key"] == key:
			return edge
	return {}

func outgoing(id: String) -> Array:
	var result: Array = []
	for neighbor: String in neighbors(id):
		var edge: Dictionary = edge_between(id, neighbor)
		result.append({"from": id, "to": neighbor, "weight": edge["weight"], "key": edge["key"]})
	return result

func route_cost(route: Array, hops: bool = false) -> int:
	var cost: int = 0
	for index: int in range(1, route.size()):
		var edge: Dictionary = edge_between(route[index - 1], route[index])
		if edge.is_empty():
			return CourierSolver.INF
		cost += 1 if hops else int(edge["weight"])
	return cost
