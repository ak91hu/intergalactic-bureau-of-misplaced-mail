class_name Main
extends Node2D

const NODE_POSITIONS := {
	"redundancy": Vector2(360, 60), "forms": Vector2(170, 210),
	"delays": Vector2(610, 210), "stamps": Vector2(110, 365),
	"lost": Vector2(460, 365), "destination": Vector2(290, 520)
}
const EDGE_COLOR := Color("526588")
@onready var graph_manager: GraphManager = $GraphManager
@onready var nodes_container: Node2D = $GraphClip/GraphLayer/NodesContainer
@onready var edges_container: Node2D = $GraphClip/GraphLayer/EdgesContainer
@onready var game_ui: GameUI = $CanvasLayer/GameUI
var department_node_map: Dictionary = {}
var _edge_map: Dictionary = {}
var mission := MissionSession.new()
var _board: Rect2
var _clock: float = 0.0
var _pan_active: bool = false
var _last_pointer := Vector2.ZERO
var _packet: Vector2 = Vector2.ZERO
var _packet_visible: bool = false
var _packet_tween: Tween
var _completion_saved: bool = false

func _ready() -> void:
	BureauTheme.apply_theme(game_ui)
	graph_manager.set_algorithm(GameState.selected_algorithm)
	mission.setup(GameState.selected_algorithm, graph_manager.timeline)
	game_ui.configure(GameState.selected_algorithm)
	game_ui.memo_label.text = graph_manager.get_active_algorithm_welcome()
	_build_nodes()
	_build_edges()
	graph_manager.frame_changed.connect(_on_frame)
	graph_manager.edge_examined.connect(_on_edge_examined)
	game_ui.advance_requested.connect(_advance)
	game_ui.rewind_requested.connect(graph_manager.rewind_algorithm)
	game_ui.answer_requested.connect(_answer)
	game_ui.reset_requested.connect(_reset)
	game_ui.hint_requested.connect(_hint)
	game_ui.menu_requested.connect(func(): get_tree().change_scene_to_file("res://MenuScene.tscn"))
	game_ui.next_mission_requested.connect(_next_mission)
	game_ui.fit_requested.connect(_fit_graph)
	get_viewport().size_changed.connect(_fit_graph)
	_fit_graph()

func _build_nodes() -> void:
	for id: String in GraphManager.DEPARTMENTS:
		var node := DepartmentNode.new()
		nodes_container.add_child(node)
		node.position = NODE_POSITIONS[id]
		node.setup(id, graph_manager.get_department_name(id))
		department_node_map[id] = node

func _build_edges() -> void:
	var index: int = GameState.selected_algorithm
	var undirected: bool = index in [5, 8]
	var absolute: bool = index in [3, 5, 6, 8]
	for from_id: String in GraphManager.DEPARTMENTS:
		for to_id: String in graph_manager.get_neighbors_of(from_id):
			var from: Vector2 = NODE_POSITIONS[from_id]
			var to: Vector2 = NODE_POSITIONS[to_id]
			var direction: Vector2 = (to - from).normalized()
			var start: Vector2 = from + direction * _card_clearance(direction)
			var finish: Vector2 = to - direction * _card_clearance(direction)
			var line := Line2D.new()
			line.default_color = EDGE_COLOR
			line.width = 2.5
			line.antialiased = true
			line.points = PackedVector2Array([start, finish])
			edges_container.add_child(line)
			var head := Line2D.new()
			head.default_color = EDGE_COLOR
			head.width = 2.5
			head.antialiased = true
			head.points = PackedVector2Array([finish - direction.rotated(-0.45) * 12, finish, finish - direction.rotated(0.45) * 12])
			head.visible = not undirected
			edges_container.add_child(head)
			var raw: int = graph_manager.get_edge_weight(from_id, to_id)
			var label := Label.new()
			label.text = str(abs(raw) if absolute else raw)
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", BureauTheme.GOLD if raw < 0 else BureauTheme.INK)
			label.add_theme_stylebox_override("normal", BureauTheme.panel(BureauTheme.SURFACE, BureauTheme.BORDER, 5))
			label.position = (start + finish) / 2 + Vector2(-12, -15)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			edges_container.add_child(label)
			_edge_map[from_id + "|" + to_id] = {"line": line, "head": head, "from": start, "to": finish}

func _card_clearance(direction: Vector2) -> float:
	var horizontal: float = 98 / maxf(absf(direction.x), 0.001)
	var vertical: float = 42 / maxf(absf(direction.y), 0.001)
	return minf(horizontal, vertical)

func _fit_graph() -> void:
	var view: Vector2 = get_viewport_rect().size
	_board = Rect2(24, 98, view.x - 442, view.y - 248)
	var available: Vector2 = _board.size - Vector2(36, 106)
	var scale_factor: float = minf(available.x / 720, available.y / 550)
	$GraphClip/GraphLayer.scale = Vector2.ONE * scale_factor
	$GraphClip.position = _board.position
	$GraphClip.size = _board.size
	$GraphClip/GraphLayer.position = Vector2(_board.size.x / 2, 73 + available.y / 2) - Vector2(360, 285) * scale_factor
	queue_redraw()

func _advance() -> void:
	if graph_manager.cursor + 1 >= graph_manager.timeline.size():
		return
	if not GameState.practice_mode:
		var question: Dictionary = mission.pending(graph_manager.cursor + 1)
		if not question.is_empty():
			game_ui.show_question(question, mission.answered.size() + 1)
			for id: String in department_node_map:
				department_node_map[id].selectable = question["node_choice"] and id in question["options"]
				department_node_map[id].queue_redraw()
			return
	graph_manager.advance_algorithm()

func _answer(choice: String) -> void:
	var result: Dictionary = mission.answer(graph_manager.cursor + 1, choice)
	if result.is_empty():
		return
	for node: DepartmentNode in department_node_map.values():
		node.selectable = false
		node.queue_redraw()
	graph_manager.advance_algorithm()
	game_ui.show_feedback(result, mission)
	_play_sound("correct" if result["correct"] else "wrong")
	if graph_manager.cursor == graph_manager.timeline.size() - 1:
		game_ui.show_completion(mission)

func _hint() -> void:
	var text: String = mission.use_hint(graph_manager.cursor + 1)
	if not text.is_empty():
		game_ui.show_hint(text)

func _on_frame(frame: Dictionary, step: int, total: int) -> void:
	for id: String in department_node_map:
		department_node_map[id].set_visual_state(frame["states"][id])
	for edge: Dictionary in _edge_map.values():
		edge["line"].default_color = EDGE_COLOR
		edge["head"].default_color = EDGE_COLOR
	game_ui.update_frame(frame, step, total)
	if frame["is_complete"]:
		_packet_visible = false
		for key: String in frame.get("solution_edges", []):
			if not _edge_map.has(key):
				var reversed: PackedStringArray = key.split("|")
				key = reversed[1] + "|" + reversed[0]
			if _edge_map.has(key):
				_edge_map[key]["line"].default_color = BureauTheme.CYAN
				_edge_map[key]["head"].default_color = BureauTheme.CYAN
		game_ui.show_completion(mission)
		if not _completion_saved:
			_completion_saved = true
			if not GameState.practice_mode:
				GameState.record_result(GameState.selected_algorithm, mission.score, mission.stars())
			_play_sound("complete")

func _on_edge_examined(from_id: String, to_id: String) -> void:
	var key: String = from_id + "|" + to_id
	if not _edge_map.has(key):
		key = to_id + "|" + from_id
	if not _edge_map.has(key):
		return
	var edge: Dictionary = _edge_map[key]
	if is_instance_valid(_packet_tween):
		_packet_tween.kill()
	_packet = $GraphClip/GraphLayer.to_global(edge["from"])
	_packet_visible = not GameState.reduced_motion
	_packet_tween = create_tween()
	_packet_tween.tween_property(self, "_packet", $GraphClip/GraphLayer.to_global(edge["to"]), 0.4)
	_packet_tween.tween_callback(func(): _packet_visible = false)
	# frame_changed restores base colors first; deferred highlighting keeps this edge visible.
	_highlight_edge.call_deferred(key)

func _highlight_edge(key: String) -> void:
	if not is_inside_tree():
		return
	var edge: Dictionary = _edge_map[key]
	edge["line"].default_color = BureauTheme.GOLD
	edge["head"].default_color = BureauTheme.GOLD

func _reset() -> void:
	if is_instance_valid(_packet_tween):
		_packet_tween.kill()
	_packet_visible = false
	_completion_saved = false
	graph_manager.reset_algorithm()
	mission.setup(GameState.selected_algorithm, graph_manager.timeline)
	for node: DepartmentNode in department_node_map.values():
		node.selectable = false
		node.set_visual_state("default")
	for edge: Dictionary in _edge_map.values():
		edge["line"].default_color = EDGE_COLOR
		edge["head"].default_color = EDGE_COLOR
	game_ui.reset_display()
	game_ui.memo_label.text = graph_manager.get_active_algorithm_welcome()
	_fit_graph()

func _next_mission() -> void:
	GameState.selected_algorithm = (GameState.selected_algorithm + 1) % 9
	get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if not GameState.reduced_motion:
		_clock += delta
		queue_redraw()
	var local: Vector2 = $GraphClip/GraphLayer.get_local_mouse_position()
	for node: DepartmentNode in department_node_map.values():
		var over: bool = Rect2(node.position - Vector2(92, 36), Vector2(184, 72)).has_point(local) and _board.has_point(get_global_mouse_position())
		if node.hovered != over:
			node.hovered = over
			node.queue_redraw()

func _draw() -> void:
	var view: Vector2 = get_viewport_rect().size
	BureauArt.space(self, Rect2(Vector2.ZERO, view), _clock)
	BureauTheme.panel(Color("0e1629"), BureauTheme.BORDER, 0).draw(get_canvas_item(), _board)
	BureauArt.space(self, Rect2(_board.position + Vector2.ONE, _board.size - Vector2.ONE * 2), _clock, true)
	var font: Font = BureauTheme.UI_FONT
	draw_string(font, _board.position + Vector2(20, 28), "SECTOR 07  /  DELIVERY NETWORK", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BureauTheme.CYAN)
	var mode: String = "Two-way lanes / absolute costs" if GameState.selected_algorithm in [5, 8] else ("One-way lanes / absolute costs" if GameState.selected_algorithm in [3, 6] else "One-way lanes / original costs")
	draw_string(font, _board.position + Vector2(20, 50), mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, BureauTheme.MUTED)
	draw_string(font, _board.position + Vector2(20, _board.size.y - 18), "AMBER: waiting    CYAN: processed    |    Scroll: zoom / middle drag: pan", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, BureauTheme.MUTED)
	if _packet_visible and _board.has_point(_packet):
		BureauArt.envelope(self, _packet, 0.7)

func _unhandled_input(event: InputEvent) -> void:
	if game_ui.is_reference_open():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_pan_active = event.pressed and _board.has_point(event.position)
			_last_pointer = event.position
		elif event.pressed and _board.has_point(event.position):
			if event.button_index == MOUSE_BUTTON_LEFT:
				for node: DepartmentNode in department_node_map.values():
					if node.selectable and Rect2(node.position - Vector2(92, 36), Vector2(184, 72)).has_point($GraphClip/GraphLayer.to_local(event.position)):
						_answer(node.department_id)
						get_viewport().set_input_as_handled()
						return
			if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				var layer: Node2D = $GraphClip/GraphLayer
				var before: Vector2 = layer.to_local(event.position)
				var zoom: float = clampf(layer.scale.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.1), 0.45, 2.0)
				layer.scale = Vector2.ONE * zoom
				layer.position += event.position - layer.to_global(before)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pan_active:
		$GraphClip/GraphLayer.position += event.position - _last_pointer
		_last_pointer = event.position

func _play_sound(cue: String) -> void:
	BureauAudio.play_cue(cue)
