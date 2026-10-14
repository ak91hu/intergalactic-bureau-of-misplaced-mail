class_name CourierBoard
extends Control

signal choice_requested(choice: String)
signal inspection_requested(message: String)
signal travel_finished

var session: CourierSession
var reduced_motion: bool = false
var matrix_visible: bool = false
var show_reference: bool = false
var hover_node: String = ""
var hover_edge: String = ""
var _clock: float = 0
var _redraw_elapsed: float = 0
var _travel_from: String = ""
var _travel_to: String = ""
var _travel_progress: float = 1
var _travel_tween: Tween
var _travel_points := PackedVector2Array()
var _geometries: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(func(): _geometries.clear(); queue_redraw())
	tooltip_text = "Kattints a választható állomásra vagy hálózati élre. A feladat magyarázata jobb oldalon látható."

func set_session(model: CourierSession) -> void:
	session = model
	_geometries.clear()
	queue_redraw()

func map_area() -> Rect2:
	return Rect2(48, 74, size.x - 96, size.y - 150)

func node_point(id: String) -> Vector2:
	var area: Rect2 = map_area()
	return area.position + area.size * session.graph.node(id)["position"]

func _geometry(edge: Dictionary) -> Dictionary:
	if _geometries.is_empty(): _build_geometries()
	return _geometries[edge["key"]]

func _build_geometries() -> void:
	var occupied: Array = []
	for edge: Dictionary in session.graph.edges:
		var geometry: Dictionary = _raw_geometry(edge)
		var preferred: Vector2 = geometry["mid"]
		var normal := Vector2(-geometry["direction"].y, geometry["direction"].x)
		var selected: Vector2 = preferred
		var best_score: int = 10000
		for along: int in [0, 12, -12, 24, -24, 36, -36, 48, -48, 60, -60, 72, -72, 96, -96]:
			for across: int in [0, 18, -18, 36, -36, 54, -54, 72, -72, 108, -108]:
				var point: Vector2 = preferred + geometry["direction"] * along + normal * across
				var rect := Rect2(point - Vector2(20,14), Vector2(40,28))
				var score: int = 0
				if not Rect2(12,62,size.x-24,size.y-104).encloses(rect): score += 100
				for node: Dictionary in session.graph.nodes:
					var center: Vector2 = node_point(node["id"])
					if rect.grow(4).intersects(Rect2(center-Vector2(35,35),Vector2(70,70))): score += 10
					if rect.grow(4).intersects(Rect2(center+Vector2(-76,35),Vector2(152,25))): score += 10
				for other: Rect2 in occupied:
					if rect.grow(3).intersects(other): score += 10
				if score < best_score:
					best_score = score
					selected = point
				if score == 0: break
			if best_score == 0: break
		geometry["line_mid"] = preferred
		geometry["mid"] = selected
		geometry["label_rect"] = Rect2(selected-Vector2(20,14),Vector2(40,28))
		occupied.append(geometry["label_rect"])
		_geometries[edge["key"]] = geometry

func _raw_geometry(edge: Dictionary) -> Dictionary:
	var from: Vector2 = node_point(edge["from"])
	var to: Vector2 = node_point(edge["to"])
	var direction: Vector2 = (to - from).normalized()
	var start: Vector2 = from + direction * 35
	var end: Vector2 = to - direction * 35
	var points := PackedVector2Array([start,end])
	if edge["key"] in ["A|D", "B|F"]:
		var top: bool = (from.y + to.y) / 2 < map_area().get_center().y
		var control: Vector2 = (from + to) / 2 + Vector2(0, map_area().size.y * (-0.65 if top else 0.8))
		start = from + (control-from).normalized()*35
		end = to - (to-control).normalized()*35
		points.clear()
		for index: int in range(25):
			var t: float = index/24.0
			points.append((1-t)*(1-t)*start + 2*(1-t)*t*control + t*t*end)
		direction = (points[24]-points[23]).normalized()
	var mid: Vector2 = points[points.size()/2] if points.size()>2 else (start+end)/2
	return {"start": start, "end": end, "mid": mid, "direction": direction, "points": points}

func _process(delta: float) -> void:
	if not reduced_motion:
		_clock += delta
		_redraw_elapsed += delta
		if _travel_progress < 1 or _redraw_elapsed >= 0.05:
			_redraw_elapsed = 0
			queue_redraw()

func _draw() -> void:
	BureauTheme.panel(Color("0d1b2d"), BureauTheme.BORDER, 0).draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	BureauArt.space(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), _clock, true)
	draw_line(Vector2(20, 61), Vector2(size.x - 20, 61), Color(BureauTheme.CYAN, 0.12), 1, true)
	draw_line(Vector2(20, size.y - 38), Vector2(size.x - 20, size.y - 38), Color(BureauTheme.CYAN, 0.12), 1, true)
	if session == null: return
	_text(Vector2(20, 27), "SZEKTOR " + session.level["sector"] + " / ŰRPOSTA", 13, BureauTheme.CYAN)
	_text(Vector2(20, 49), "Kétirányú hálózat · összköltség" if not session.graph.directed else "A nyilak egyirányú sávokat jelölnek", 13, BureauTheme.MUTED)
	if matrix_visible:
		_draw_matrix()
		return
	var offered: Array = []
	for option: Dictionary in session.choices(): offered.append(option["id"])
	var reference_path: Array = []
	if show_reference and session.phase in ["ready", "delivery", "failed", "complete"] and not CourierLessons.is_network(session.algorithm()) and session.algorithm() != 2:
		reference_path = session.optimal_route()
	for edge: Dictionary in session.graph.edges:
		_draw_edge(edge, offered, reference_path)
	for node: Dictionary in session.graph.nodes:
		_draw_station(node, offered)
	if session.phase in ["delivery", "next_package", "failed", "complete"] and not session.route.is_empty():
		var point: Vector2 = node_point(session.route.back()) + Vector2(0, -44)
		if _travel_progress < 1:
			point = travel_point()
			for trail: int in range(1, 8):
				var trail_point: Vector2 = travel_point(maxf(0, _travel_progress - trail * 0.018))
				draw_circle(trail_point, 4.0 - trail * 0.35, Color(BureauTheme.GOLD, 0.38 - trail * 0.045))
		_draw_parcel(point)
	elif session.phase in ["briefing", "ready"]:
		_draw_parcel(node_point(session.source()) + Vector2(0, -45))
	var legend: String = "Arany: frontier   ·   Türkiz: feldolgozva   ·   Szaggatott piros: lezárás"
	if session.phase == "delivery": legend = "Válassz következő állomást. A vastag vonal a saját kézbesítési utad."
	elif session.algorithm() == 2: legend = "A feladási sorrend előfeltételeket követ, nem fizikai útvonalat."
	elif CourierLessons.is_network(session.algorithm()): legend = "Türkiz: bekötött kapcsolat   ·   Lila: választható él   ·   ×: lezárás"
	_text(Vector2(20, size.y - 18), legend, 12, BureauTheme.MUTED)

func _draw_edge(edge: Dictionary, offered: Array, reference_path: Array) -> void:
	var geometry: Dictionary = _geometry(edge)
	var color := Color("58748e")
	var width: float = 2
	var key: String = edge["key"]
	var closed: bool = edge["closed"]
	var chosen: bool = key in session.tree
	for index: int in range(1, session.route.size()):
		chosen = chosen or session.graph.edge_between(session.route[index - 1], session.route[index])["key"] == key
	var recommended: bool = false
	for index: int in range(1, reference_path.size()):
		recommended = recommended or session.graph.edge_between(reference_path[index - 1], reference_path[index])["key"] == key
	if closed:
		color = Color(BureauTheme.RED, 0.5)
	elif chosen:
		color = BureauTheme.CYAN
		width = 4
	elif "edge:" + key in offered:
		color = Color(BureauTheme.VIOLET, 0.75)
		width = 2.5
	elif session.phase == "delivery" and (edge["from"] == session.route.back() or (not session.graph.directed and edge["to"] == session.route.back())):
		color = BureauTheme.GOLD
		width = 3
	if hover_edge == key and not closed:
		color = BureauTheme.INK
		width = 4
	var points: PackedVector2Array = geometry["points"]
	if not closed and width > 2:
		draw_polyline(points, Color(color, 0.045), width + 13, true)
		draw_polyline(points, Color(color, 0.09), width + 5, true)
	for index: int in range(1,points.size()):
		if closed: draw_dashed_line(points[index-1],points[index],color,2,7,true)
		else:
			draw_line(points[index-1], points[index], Color(0, 0, 0, 0.3), width + 2, true)
			draw_line(points[index-1],points[index],color,width,true)
		if recommended and not chosen: draw_dashed_line(points[index-1]+Vector2(0,-5),points[index]+Vector2(0,-5),BureauTheme.GOLD,2,5,true)
	if session.graph.directed:
		var tip: Vector2 = geometry["end"]
		var direction: Vector2 = geometry["direction"]
		draw_colored_polygon(PackedVector2Array([tip, tip - direction.rotated(0.4) * 11, tip - direction.rotated(-0.4) * 11]), color)
	if chosen and not reduced_motion:
		var pulse: float = fmod(_clock * 0.24 + float(key.hash() % 100) / 100, 1)
		var segment: float = pulse * (points.size() - 1)
		var index: int = mini(int(segment), points.size() - 2)
		var point: Vector2 = points[index].lerp(points[index + 1], segment - index)
		draw_circle(point, 3, Color(BureauTheme.INK, 0.85))
		BureauArt.glow(self, point, 12, color, 2)
	var rect: Rect2 = geometry["label_rect"]
	if geometry["mid"].distance_to(geometry["line_mid"])>18:
		draw_line(geometry["line_mid"],geometry["mid"],Color(color,0.45),1,true)
	var tag := BureauTheme.panel(Color("16293c"), color.darkened(0.2), 0)
	tag.set_corner_radius_all(9)
	tag.shadow_color = Color(0, 0, 0, 0.3)
	tag.shadow_size = 3
	tag.shadow_offset = Vector2(0, 2)
	tag.draw(get_canvas_item(), rect)
	_text(rect.position + Vector2(0, 20), "×" if closed else str(edge["weight"]), 17, BureauTheme.RED if closed else (BureauTheme.GOLD if edge["weight"] < 0 else BureauTheme.INK), 40, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_station(node: Dictionary, offered: Array) -> void:
	var id: String = node["id"]
	var point: Vector2 = node_point(id)
	var processed: bool = session.visited.get(id, false)
	var color: Color = BureauTheme.CYAN if processed else BureauTheme.BORDER
	var planet_color: Color = BureauTheme.CYAN if processed else Color("648bb8")
	if id in session.frontier and session.algorithm() in [0, 1, 3, 6]:
		color = BureauTheme.GOLD
		planet_color = BureauTheme.GOLD
	if "node:" + id in offered:
		color = BureauTheme.VIOLET if session.phase in ["order", "matrix"] else BureauTheme.GOLD
		planet_color = color
	if hover_node == id: color = BureauTheme.INK
	if id == session.target() and not CourierLessons.is_network(session.algorithm()) and session.algorithm()!=2:
		draw_arc(point, 42, -0.5, 2.3, 40, Color(BureauTheme.CYAN, 0.7), 2, true)
		draw_arc(point, 42, 2.6, 5.5, 40, Color(BureauTheme.CYAN, 0.7), 2, true)
	if id == session.source() and session.algorithm()!=8:
		draw_arc(point, 38, 0, TAU, 64, Color(BureauTheme.GOLD, 0.5), 1, true)
	if "node:" + id in offered and not reduced_motion:
		draw_circle(point, 36 + 2 * sin(_clock * 2.6), Color(color, 0.08))
	BureauArt.planet(self, point, 30, planet_color, id.unicode_at(0))
	draw_arc(point, 30, 0, TAU, 64, color, 2, true)
	draw_circle(point + Vector2(23, -21), 5, Color("0c1728"))
	draw_circle(point + Vector2(23, -21), 2.5, color if color != BureauTheme.BORDER else BureauTheme.MUTED)
	draw_string_outline(BureauTheme.UI_FONT, point + Vector2(-30, 9), id, HORIZONTAL_ALIGNMENT_CENTER, 60, 26, 4, Color("0b1726"))
	_text(point + Vector2(-30, 9), id, 26, BureauTheme.INK, 60, HORIZONTAL_ALIGNMENT_CENTER)
	var badge: String = ""
	if session.algorithm() == 2:
		badge = "feladva" if processed else "%d előfeltétel" % session.indegree[id]
	elif CourierLessons.is_network(session.algorithm()):
		badge = "csoport: " + CourierSolver.root(session.components, id)
	elif session.algorithm() == 6:
		badge = "g=%s h=%.1f" % [CourierSession.number(session.distances[id]), session.h[id]]
	elif session.algorithm() == 7:
		badge = "köztes: kész" if id in session.relays else "köztes: vár"
	else:
		badge = "d=" + CourierSession.number(session.distances[id])
	if not CourierLessons.is_network(session.algorithm()) and session.algorithm()!=2:
		if id==session.source(): badge="Feladó · "+badge
		elif id==session.target(): badge="Címzett · "+badge
	BureauTheme.panel(Color("0d1b2d"),Color(0,0,0,0),0).draw(get_canvas_item(),Rect2(point+Vector2(-76,35),Vector2(152,25)))
	_text(point + Vector2(-76, 51), badge, 12, color if color != BureauTheme.BORDER else BureauTheme.MUTED, 152, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_parcel(point: Vector2) -> void:
	BureauArt.envelope(self, point, 0.85)

func _draw_matrix() -> void:
	var ids: Array = session.graph.ids()
	var cell: Vector2 = Vector2(minf(58, (size.x - 110) / ids.size()), minf(43, (size.y - 155) / (ids.size() + 1)))
	var origin := Vector2((size.x - cell.x * ids.size()) / 2, 110)
	_text(Vector2(24, 78), "SOR = FELADÓ    /    OSZLOP = CÍMZETT", 13, BureauTheme.VIOLET)
	for row_index: int in ids.size():
		var from: String = ids[row_index]
		_text(origin + Vector2(-32, row_index * cell.y + 26), from, 18, BureauTheme.INK)
		var header := Rect2(origin + Vector2(row_index * cell.x, -34), Vector2(cell.x - 3, 29))
		BureauTheme.panel(BureauTheme.RAISED, BureauTheme.CYAN if from in session.relays else BureauTheme.VIOLET, 0).draw(get_canvas_item(), header)
		_text(header.position + Vector2(0, 21), from, 17, BureauTheme.INK, header.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		for col_index: int in ids.size():
			var to: String = ids[col_index]
			var rect := Rect2(origin + Vector2(col_index * cell.x, row_index * cell.y), cell - Vector2(3,3))
			var changed: bool = false
			for change: Dictionary in session.last_changes: changed = changed or (change["from"] == from and change["to"] == to)
			var color: Color = Color("173b3d") if changed else BureauTheme.SURFACE
			var border: Color = BureauTheme.CYAN if changed else BureauTheme.BORDER
			if from == session.source() and to == session.target(): border = BureauTheme.GOLD
			BureauTheme.panel(color, border, 0).draw(get_canvas_item(), rect)
			_text(rect.position + Vector2(0, rect.size.y / 2 + 6), CourierSession.number(session.matrix[from][to]), 18, BureauTheme.CYAN if changed else BureauTheme.INK, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(24, size.y - 25), "Türkiz: most javult. Arany keret: az aktuális csomag feladó–címzett párja.", 12, BureauTheme.MUTED)

func _text(point: Vector2, text: String, font_size: int, color: Color, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(BureauTheme.UI_FONT, point, text, align, width, font_size, color)

func _gui_input(event: InputEvent) -> void:
	if session == null: return
	if event is InputEventMouseMotion:
		hover_node = ""
		hover_edge = ""
		if not matrix_visible:
			for node: Dictionary in session.graph.nodes:
				if event.position.distance_to(node_point(node["id"])) < 35: hover_node = node["id"]
			for edge: Dictionary in session.graph.edges:
				var geometry: Dictionary = _geometry(edge)
				if event.position.distance_to(geometry["mid"]) < 24: hover_edge = edge["key"]
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var offered: Array = []
		for option: Dictionary in session.choices(): offered.append(option["id"])
		if matrix_visible:
			var ids: Array = session.graph.ids()
			var cell_x: float = minf(58, (size.x - 110) / ids.size())
			var origin_x: float = (size.x - cell_x * ids.size()) / 2
			if event.position.y > 76 and event.position.y < 110 and event.position.x >= origin_x and event.position.x < origin_x + ids.size() * cell_x:
				var col: int = int((event.position.x - origin_x) / cell_x)
				if col >= 0 and col < ids.size() and "node:" + ids[col] in offered: choice_requested.emit("node:" + ids[col])
			return
		for node: Dictionary in session.graph.nodes:
			if event.position.distance_to(node_point(node["id"])) < 35:
				if "node:" + node["id"] in offered:
					choice_requested.emit("node:" + node["id"])
				else:
					inspection_requested.emit("%s / %s. %s" % [node["id"], node["name"], "Feladó." if node["id"] == session.source() else ("Címzett." if node["id"] == session.target() else "A választható lépések jobb oldalon láthatók.")])
				accept_event()
				return
		for edge: Dictionary in session.graph.edges:
			var geometry: Dictionary = _geometry(edge)
			var close: bool = _hit_edge(event.position,geometry)
			if close:
				if "edge:" + edge["key"] in offered:
					choice_requested.emit("edge:" + edge["key"])
				else:
					inspection_requested.emit("%s: %s" % [edge["key"].replace("|", " → "), "ionvihar miatt lezárva; nem használható." if edge["closed"] else "%d kredit. A nyíl irányában járható." % edge["weight"]])
				accept_event()
				return

func _hit_edge(point: Vector2, geometry: Dictionary) -> bool:
	if geometry["label_rect"].grow(4).has_point(point): return true
	var points: PackedVector2Array = geometry["points"]
	for index: int in range(1,points.size()):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,points[index-1],points[index]))<7: return true
	return false

func _get_tooltip(at_position: Vector2) -> String:
	if session == null: return ""
	for node: Dictionary in session.graph.nodes:
		if at_position.distance_to(node_point(node["id"]))<35: return node["id"]+" / "+node["name"]
	for edge: Dictionary in session.graph.edges:
		if _hit_edge(at_position,_geometry(edge)): return edge["key"].replace("|"," → ")+": "+("lezárva" if edge["closed"] else str(edge["weight"])+" kredit")
	return ""

func animate_packet(from: String, to: String) -> void:
	if reduced_motion:
		travel_finished.emit()
		return
	if is_instance_valid(_travel_tween): _travel_tween.kill()
	_travel_from = from
	_travel_to = to
	var edge: Dictionary = session.graph.edge_between(from,to)
	_travel_points = _geometry(edge)["points"].duplicate()
	if edge["from"] != from: _travel_points.reverse()
	_travel_points.insert(0,node_point(from))
	_travel_points.append(node_point(to))
	_travel_progress = 0
	_travel_tween = create_tween()
	_travel_tween.tween_property(self, "_travel_progress", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_travel_tween.tween_callback(func(): travel_finished.emit())

func travel_point(progress: float = -1) -> Vector2:
	if _travel_points.is_empty(): return node_point(_travel_to)
	var total: float = 0
	for index: int in range(1,_travel_points.size()):
		total += _travel_points[index-1].distance_to(_travel_points[index])
	var remaining: float = total * clampf(_travel_progress if progress < 0 else progress,0,1)
	for index: int in range(1,_travel_points.size()):
		var length: float = _travel_points[index-1].distance_to(_travel_points[index])
		if remaining <= length:
			return _travel_points[index-1].lerp(_travel_points[index],remaining/maxf(length,0.001))
		remaining -= length
	return _travel_points[-1]

func stop_travel() -> void:
	if is_instance_valid(_travel_tween): _travel_tween.kill()
	_travel_progress = 1
	queue_redraw()
