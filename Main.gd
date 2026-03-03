class_name Main
extends Node2D

const DepartmentNodeScene: PackedScene = preload("res://DepartmentNode.tscn")

const NODE_POSITIONS: Dictionary = {
	"redundancy":  Vector2(640, 110),
	"forms":       Vector2(380, 270),
	"delays":      Vector2(900, 270),
	"stamps":      Vector2(240, 440),
	"lost":        Vector2(620, 440),
	"destination": Vector2(430, 600)
}

# Galaxy palette (kept in sync with GameUI.gd / MenuScene.gd)
const M_SURFACE:     Color = Color(0.07, 0.05, 0.13)
const M_SURFACE_V:   Color = Color(0.12, 0.09, 0.22)
const M_PRIMARY:     Color = Color(0.52, 0.32, 1.00)
const M_PRIMARY_C:   Color = Color(0.15, 0.09, 0.36)
const M_SECONDARY:   Color = Color(0.08, 0.88, 0.82)
const M_ON_SURF:     Color = Color(0.93, 0.90, 1.00)
const M_ON_SURF_V:   Color = Color(0.57, 0.52, 0.75)
const M_OUTLINE:     Color = Color(0.20, 0.16, 0.38)
const SHADOW_COL:    Color = Color(0.00, 0.00, 0.08, 0.70)

const RADIUS_BTN:  int = 8

const EDGE_COLOR:           Color = Color(0.52, 0.32, 1.00, 0.60)
const EDGE_HIGHLIGHT_COLOR: Color = Color(0.08, 0.88, 0.82, 1.0)
const EDGE_WIDTH:           float = 2.0
const EDGE_NODE_CLEARANCE:  float = 100.0
const ARROW_HEAD_LENGTH:    float = 13.0
const ARROW_HALF_ANGLE:     float = 0.42
const WEIGHT_LABEL_COLOR:   Color = Color(0.93, 0.90, 1.00, 0.90)
const M_BG:                 Color = Color(0.03, 0.02, 0.08)

@onready var graph_manager:   GraphManager = $GraphManager
@onready var nodes_container: Node2D       = $GraphLayer/NodesContainer
@onready var edges_container: Node2D       = $GraphLayer/EdgesContainer
@onready var game_ui:         GameUI       = $CanvasLayer/GameUI

var department_node_map: Dictionary = {}
var _edge_map: Dictionary = {}  # "from_id|to_id" -> {shaft: Line2D, head: Line2D}

# ─── Starfield ────────────────────────────────────────────────────────────────
var _stars: Array = []    # [Vector2, radius, base_alpha, speed, phase, tier_int]
var _bg_time: float = 0.0

# ─── Graph panning ────────────────────────────────────────────────────────────
var _pan_active: bool     = false
var _pan_last:   Vector2  = Vector2.ZERO

var _hint_overlay:  Panel = null
var _tooltip_panel: Panel = null
var _tooltip_label: Label = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_pan_active = event.pressed
			if event.pressed:
				_pan_last = event.position
	elif event is InputEventMouseMotion and _pan_active:
		$GraphLayer.position += event.position - _pan_last
		_pan_last = event.position


func _process(delta: float) -> void:
	_bg_time += delta
	queue_redraw()
	_update_tooltip()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), M_BG)
	draw_circle(Vector2(640,  360), 700, Color(0.10, 0.04, 0.22, 0.06))
	draw_circle(Vector2(1020, 190), 420, Color(0.25, 0.06, 0.50, 0.11))
	draw_circle(Vector2(1020, 190), 220, Color(0.32, 0.08, 0.60, 0.07))
	draw_circle(Vector2(150,  560), 340, Color(0.04, 0.14, 0.52, 0.10))
	draw_circle(Vector2(150,  560), 160, Color(0.06, 0.18, 0.62, 0.06))
	draw_circle(Vector2(720,  700), 260, Color(0.06, 0.22, 0.45, 0.08))
	draw_circle(Vector2(220,  140), 180, Color(0.22, 0.06, 0.38, 0.06))
	for star: Array in _stars:
		var a: float = star[2] + sin(_bg_time * star[3] + star[4]) * 0.18
		var sc: Color = Color(0.94, 0.91, 1.0, clampf(a, 0.05, 0.92)) if star[5] == 0 else Color(0.98, 0.94, 0.88, clampf(a, 0.05, 0.92))
		draw_circle(star[0], star[1], sc)


func _ready() -> void:
	randomize()
	for i: int in range(160):  # far tier
		_stars.append([
			Vector2(randf_range(0, 1280), randf_range(0, 720)),
			randf_range(0.3, 1.0),
			randf_range(0.06, 0.28),
			randf_range(0.3, 1.2),
			randf_range(0.0, TAU),
			0
		])
	for i: int in range(90):   # near tier
		_stars.append([
			Vector2(randf_range(0, 1280), randf_range(0, 720)),
			randf_range(1.0, 2.8),
			randf_range(0.30, 0.72),
			randf_range(1.0, 2.8),
			randf_range(0.0, TAU),
			1
		])

	_build_node_visuals()
	_build_edge_visuals()
	_wire_signals()
	_add_title_banner()
	_add_color_legend()
	_add_back_button()
	game_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	var algo_idx: int = GameState.selected_algorithm
	graph_manager.set_algorithm(algo_idx)
	game_ui.update_form_header(GameUI.ALGORITHM_FORM_CODES[algo_idx])
	game_ui.update_structure_label(GameUI.ALGORITHM_STRUCTURE_LABELS[algo_idx])
	game_ui.update_welcome(graph_manager.get_active_algorithm_welcome())
	game_ui.update_info_panel(algo_idx)
	_add_hint_overlay()
	_add_tooltip_panel()


func _build_node_visuals() -> void:
	for dept_id: String in graph_manager.get_all_department_ids():
		var dept_node: DepartmentNode = DepartmentNodeScene.instantiate()
		nodes_container.add_child(dept_node)
		dept_node.position = NODE_POSITIONS[dept_id]
		dept_node.setup(dept_id, graph_manager.get_department_name(dept_id))
		department_node_map[dept_id] = dept_node


func _build_edge_visuals() -> void:
	for dept_id: String in graph_manager.get_all_department_ids():
		for neighbor_id: String in graph_manager.get_neighbors_of(dept_id):
			var weight: int = graph_manager.get_edge_weight(dept_id, neighbor_id)
			var edge_data: Dictionary = _draw_directed_edge(NODE_POSITIONS[dept_id], NODE_POSITIONS[neighbor_id], weight)
			_edge_map["%s|%s" % [dept_id, neighbor_id]] = edge_data


func _draw_directed_edge(from_world: Vector2, to_world: Vector2, weight: int = 0) -> Dictionary:
	var direction:  Vector2 = (to_world - from_world).normalized()
	var edge_start: Vector2 = from_world + direction * EDGE_NODE_CLEARANCE
	var edge_end:   Vector2 = to_world   - direction * EDGE_NODE_CLEARANCE

	var shaft := Line2D.new()
	shaft.default_color = EDGE_COLOR
	shaft.width = EDGE_WIDTH
	shaft.add_point(edge_start)
	shaft.add_point(edge_end)
	edges_container.add_child(shaft)

	var backward: Vector2 = -direction
	var arrowhead := Line2D.new()
	arrowhead.default_color = EDGE_COLOR
	arrowhead.width = EDGE_WIDTH
	arrowhead.add_point(edge_end + backward.rotated(-ARROW_HALF_ANGLE) * ARROW_HEAD_LENGTH)
	arrowhead.add_point(edge_end)
	arrowhead.add_point(edge_end + backward.rotated( ARROW_HALF_ANGLE) * ARROW_HEAD_LENGTH)
	edges_container.add_child(arrowhead)

	# Weight label — small pill panel
	var midpoint: Vector2 = (edge_start + edge_end) * 0.5
	var weight_container := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.12, 0.09, 0.22, 0.85)
	cs.border_color = Color(0.20, 0.16, 0.38, 0.60)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(4)
	cs.shadow_color = SHADOW_COL
	cs.shadow_size  = 3
	cs.content_margin_left  = 3;  cs.content_margin_right  = 3
	cs.content_margin_top   = 1;  cs.content_margin_bottom = 1
	weight_container.add_theme_stylebox_override("panel", cs)
	weight_container.position    = midpoint + Vector2(-14.0, -22.0)
	weight_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var weight_label := Label.new()
	weight_label.text = str(weight)
	weight_label.add_theme_font_size_override("font_size", 10)
	weight_label.add_theme_color_override("font_color", WEIGHT_LABEL_COLOR)
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_container.add_child(weight_label)
	edges_container.add_child(weight_container)

	return {"shaft": shaft, "head": arrowhead}


func _wire_signals() -> void:
	graph_manager.node_state_changed.connect(_on_node_state_changed)
	graph_manager.queue_updated.connect(game_ui.update_queue_display)
	graph_manager.step_message_changed.connect(game_ui.update_message)
	graph_manager.algorithm_complete.connect(game_ui.disable_advance_button)
	graph_manager.edge_examined.connect(_on_edge_examined)
	game_ui.advance_requested.connect(graph_manager.advance_algorithm)
	game_ui.reset_requested.connect(_on_reset_requested)


func _on_node_state_changed(dept_id: String, new_state: String) -> void:
	if department_node_map.has(dept_id):
		department_node_map[dept_id].set_visual_state(new_state)


func _on_reset_requested() -> void:
	graph_manager.reset_algorithm()
	_reset_all_node_visuals()
	game_ui.enable_advance_button()
	game_ui.update_queue_display([])
	game_ui.update_welcome(graph_manager.get_active_algorithm_welcome())


func _on_edge_examined(from_id: String, to_id: String) -> void:
	var key: String = "%s|%s" % [from_id, to_id]
	if not _edge_map.has(key):
		return
	var edge_data: Dictionary = _edge_map[key]
	var t := create_tween()
	t.tween_property(edge_data["shaft"], "default_color", EDGE_HIGHLIGHT_COLOR, 0.1)
	t.tween_property(edge_data["shaft"], "default_color", EDGE_COLOR, 0.55)
	var t2 := create_tween()
	t2.tween_property(edge_data["head"], "default_color", EDGE_HIGHLIGHT_COLOR, 0.1)
	t2.tween_property(edge_data["head"], "default_color", EDGE_COLOR, 0.55)


func _reset_all_node_visuals() -> void:
	for dept_id: String in department_node_map:
		department_node_map[dept_id].set_visual_state("default")


func _add_back_button() -> void:
	var canvas_layer: CanvasLayer = $CanvasLayer
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "< Menu"
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.position = Vector2(8.0, 8.0)

	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = M_SURFACE_V;  btn_n.border_color = M_OUTLINE
	btn_n.set_border_width_all(1);  btn_n.set_corner_radius_all(RADIUS_BTN)
	btn_n.content_margin_left = 12;  btn_n.content_margin_right = 12
	btn_n.content_margin_top  = 5;   btn_n.content_margin_bottom = 5

	var btn_h := StyleBoxFlat.new()
	btn_h.bg_color = M_PRIMARY_C;  btn_h.border_color = M_PRIMARY
	btn_h.set_border_width_all(1);  btn_h.set_corner_radius_all(RADIUS_BTN)
	btn_h.content_margin_left = 12;  btn_h.content_margin_right = 12
	btn_h.content_margin_top  = 5;   btn_h.content_margin_bottom = 5

	var btn_p := StyleBoxFlat.new()
	btn_p.bg_color = M_SURFACE;  btn_p.border_color = M_PRIMARY
	btn_p.set_border_width_all(2);  btn_p.set_corner_radius_all(RADIUS_BTN)
	btn_p.content_margin_left = 12;  btn_p.content_margin_right = 12
	btn_p.content_margin_top  = 5;   btn_p.content_margin_bottom = 5

	var btn_f := StyleBoxFlat.new()
	btn_f.bg_color = M_PRIMARY_C;  btn_f.border_color = M_SECONDARY
	btn_f.set_border_width_all(2);  btn_f.set_corner_radius_all(RADIUS_BTN)
	btn_f.content_margin_left = 12;  btn_f.content_margin_right = 12
	btn_f.content_margin_top  = 5;   btn_f.content_margin_bottom = 5
	btn_n.shadow_color = SHADOW_COL;  btn_n.shadow_size = 4
	btn_h.shadow_color = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.35)
	btn_h.shadow_size  = 8

	back_btn.add_theme_stylebox_override("normal",  btn_n)
	back_btn.add_theme_stylebox_override("hover",   btn_h)
	back_btn.add_theme_stylebox_override("pressed", btn_p)
	back_btn.add_theme_stylebox_override("focus",   btn_f)
	back_btn.add_theme_color_override("font_color",       M_ON_SURF)
	back_btn.add_theme_color_override("font_hover_color", M_ON_SURF)
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.pressed.connect(
		func() -> void: get_tree().change_scene_to_file("res://MenuScene.tscn")
	)
	canvas_layer.add_child(back_btn)


func _add_title_banner() -> void:
	var canvas_layer: CanvasLayer = $CanvasLayer
	var title := Label.new()
	title.name = "TitleBanner"
	title.text = "INTERGALACTIC BUREAU  ·  MISPLACED MAIL DIVISION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", M_ON_SURF_V)
	title.add_theme_color_override("font_shadow_color", Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.45))
	title.add_theme_constant_override("shadow_outline_size", 4)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position = Vector2(0.0, 10.0)
	canvas_layer.add_child(title)

	# Pan hint — shown below title
	var hint := Label.new()
	hint.name = "PanHint"
	hint.text = "drag to pan graph"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(M_ON_SURF_V.r, M_ON_SURF_V.g, M_ON_SURF_V.b, 0.45))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.position = Vector2(0.0, 26.0)
	canvas_layer.add_child(hint)


func _add_color_legend() -> void:
	var canvas_layer: CanvasLayer = $CanvasLayer

	var legend_panel := PanelContainer.new()
	legend_panel.name = "ColorLegend"
	legend_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	legend_panel.offset_left   = -215.0
	legend_panel.offset_top    =  28.0
	legend_panel.offset_right  =  -8.0
	legend_panel.offset_bottom =  28.0

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.07, 0.05, 0.13, 0.92)
	ps.border_color = M_OUTLINE
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(8)
	ps.shadow_color = SHADOW_COL
	ps.shadow_size  = 6
	legend_panel.add_theme_stylebox_override("panel", ps)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   8)
	margin.add_theme_constant_override("margin_right",  8)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	legend_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "NODE STATES"
	title_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	title_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(title_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = M_OUTLINE
	sep_style.set_content_margin_all(0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.add_theme_constant_override("separation", 2)
	vbox.add_child(sep)

	var states: Array[Array] = [
		[GameUI.C_STATE_DEFAULT,  "Undiscovered"],
		[GameUI.C_STATE_FRONTIER, "Active / In Queue"],
		[GameUI.C_STATE_VISITED,  "Processed / Done"],
	]
	for state_info: Array in states:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var swatch := PanelContainer.new()
		swatch.custom_minimum_size = Vector2(13, 13)
		var ss := StyleBoxFlat.new()
		ss.bg_color = state_info[0]
		ss.set_corner_radius_all(3)
		ss.set_content_margin_all(0)
		swatch.add_theme_stylebox_override("panel", ss)
		row.add_child(swatch)

		var lbl := Label.new()
		lbl.text = state_info[1]
		lbl.add_theme_color_override("font_color", M_ON_SURF)
		lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(lbl)

	canvas_layer.add_child(legend_panel)


func _add_hint_overlay() -> void:
	var canvas_layer: CanvasLayer = $CanvasLayer
	var algo_idx: int = GameState.selected_algorithm

	# Full intro screen — covers the graph area, dismissed by "Begin Mission"
	_hint_overlay = Panel.new()
	_hint_overlay.name = "IntroScreen"
	_hint_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint_overlay.offset_bottom = -210.0
	_hint_overlay.mouse_filter  = Control.MOUSE_FILTER_STOP

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.02, 0.09, 0.96)
	ps.set_border_width_all(0)
	ps.set_corner_radius_all(0)
	_hint_overlay.add_theme_stylebox_override("panel", ps)

	# Outer margin container
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left",   28)
	outer.add_theme_constant_override("margin_right",  28)
	outer.add_theme_constant_override("margin_top",    20)
	outer.add_theme_constant_override("margin_bottom", 16)
	_hint_overlay.add_child(outer)

	var content_vbox := VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 14)
	outer.add_child(content_vbox)

	# ── Algorithm name banner ──
	var name_lbl := Label.new()
	name_lbl.text = GameUI.ALGORITHM_NAMES[algo_idx].to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", M_PRIMARY)
	name_lbl.add_theme_color_override("font_shadow_color",
		Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.50))
	name_lbl.add_theme_constant_override("shadow_outline_size", 6)
	name_lbl.add_theme_constant_override("shadow_offset_y", 3)
	content_vbox.add_child(name_lbl)

	# ── Divider ──
	var sep1 := _make_thin_sep(M_OUTLINE)
	content_vbox.add_child(sep1)

	# ── Two-column body: ASCII art (left) + how-it-works (right) ──
	var body_row := HBoxContainer.new()
	body_row.add_theme_constant_override("separation", 20)
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(body_row)

	# Left: ASCII art panel
	var art_panel := PanelContainer.new()
	art_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var art_style := StyleBoxFlat.new()
	art_style.bg_color     = Color(0.05, 0.03, 0.14, 0.90)
	art_style.border_color = M_PRIMARY
	art_style.set_border_width_all(1)
	art_style.set_corner_radius_all(10)
	art_style.content_margin_left  = 14
	art_style.content_margin_right = 14
	art_style.content_margin_top   = 12
	art_style.content_margin_bottom = 12
	art_panel.add_theme_stylebox_override("panel", art_style)

	var art_lbl := Label.new()
	art_lbl.text = GameUI.ALGORITHM_ASCII_ART[algo_idx]
	art_lbl.add_theme_font_size_override("font_size", 11)
	art_lbl.add_theme_color_override("font_color", M_SECONDARY)
	art_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	art_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_panel.add_child(art_lbl)
	body_row.add_child(art_panel)

	# Right: description text
	var desc_vbox := VBoxContainer.new()
	desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	desc_vbox.add_theme_constant_override("separation", 8)
	body_row.add_child(desc_vbox)

	var how_title := Label.new()
	how_title.text = "HOW IT WORKS"
	how_title.add_theme_font_size_override("font_size", 10)
	how_title.add_theme_color_override("font_color", M_SECONDARY)
	desc_vbox.add_child(how_title)

	var how_lbl := Label.new()
	how_lbl.text = GameUI.ALGORITHM_INFO[algo_idx]["how_it_works"]
	how_lbl.add_theme_font_size_override("font_size", 12)
	how_lbl.add_theme_color_override("font_color", M_ON_SURF)
	how_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	how_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(how_lbl)

	var watch_title := Label.new()
	watch_title.text = "WHAT TO WATCH FOR"
	watch_title.add_theme_font_size_override("font_size", 10)
	watch_title.add_theme_color_override("font_color", M_SECONDARY)
	desc_vbox.add_child(watch_title)

	var watch_lbl := Label.new()
	watch_lbl.text = GameUI.ALGORITHM_INFO[algo_idx]["watch_for"]
	watch_lbl.add_theme_font_size_override("font_size", 11)
	watch_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	watch_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	watch_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watch_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(watch_lbl)

	# ── Divider ──
	content_vbox.add_child(_make_thin_sep(M_OUTLINE))

	# ── Bottom bar: complexity chip + Begin Mission button ──
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	content_vbox.add_child(bottom_row)

	var complexity_panel := PanelContainer.new()
	var cp_style := StyleBoxFlat.new()
	cp_style.bg_color     = Color(0.05, 0.03, 0.14, 0.80)
	cp_style.border_color = M_OUTLINE
	cp_style.set_border_width_all(1)
	cp_style.set_corner_radius_all(8)
	cp_style.content_margin_left  = 10
	cp_style.content_margin_right = 10
	cp_style.content_margin_top   = 6
	cp_style.content_margin_bottom = 6
	complexity_panel.add_theme_stylebox_override("panel", cp_style)
	var complexity_lbl := Label.new()
	complexity_lbl.text = GameUI.ALGORITHM_INFO[algo_idx]["complexity"]
	complexity_lbl.add_theme_font_size_override("font_size", 10)
	complexity_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	complexity_panel.add_child(complexity_lbl)
	complexity_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(complexity_panel)

	var begin_btn := Button.new()
	begin_btn.name = "BeginMissionButton"
	begin_btn.text = ">> Begin Mission"
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = M_PRIMARY
	btn_n.set_border_width_all(0)
	btn_n.set_corner_radius_all(RADIUS_BTN)
	btn_n.content_margin_left  = 20;  btn_n.content_margin_right  = 20
	btn_n.content_margin_top   = 10;  btn_n.content_margin_bottom = 10
	btn_n.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.55)
	btn_n.shadow_size   = 12
	btn_n.shadow_offset = Vector2(0, 4)
	var btn_h := StyleBoxFlat.new()
	btn_h.bg_color = Color(0.62, 0.42, 1.00)
	btn_h.set_border_width_all(0);  btn_h.set_corner_radius_all(RADIUS_BTN)
	btn_h.content_margin_left  = 20;  btn_h.content_margin_right  = 20
	btn_h.content_margin_top   = 10;  btn_h.content_margin_bottom = 10
	btn_h.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.55)
	btn_h.shadow_size   = 16
	var btn_f := StyleBoxFlat.new()
	btn_f.bg_color = Color(0.62, 0.42, 1.00);  btn_f.border_color = M_SECONDARY
	btn_f.set_border_width_all(2);  btn_f.set_corner_radius_all(RADIUS_BTN)
	btn_f.content_margin_left  = 20;  btn_f.content_margin_right  = 20
	btn_f.content_margin_top   = 10;  btn_f.content_margin_bottom = 10
	begin_btn.add_theme_stylebox_override("normal",  btn_n)
	begin_btn.add_theme_stylebox_override("hover",   btn_h)
	begin_btn.add_theme_stylebox_override("pressed", btn_n)
	begin_btn.add_theme_stylebox_override("focus",   btn_f)
	begin_btn.add_theme_color_override("font_color",         Color.WHITE)
	begin_btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	begin_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	begin_btn.add_theme_color_override("font_focus_color",   Color.WHITE)
	begin_btn.add_theme_font_size_override("font_size", 14)
	begin_btn.pressed.connect(_on_intro_dismissed)
	bottom_row.add_child(begin_btn)

	canvas_layer.add_child(_hint_overlay)


func _make_thin_sep(color: Color) -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(1.0)
	sep.add_theme_stylebox_override("separator", style)
	sep.add_theme_constant_override("separation", 2)
	return sep


func _on_intro_dismissed() -> void:
	if not _hint_overlay:
		return
	var node: Panel = _hint_overlay
	_hint_overlay = null
	var t := create_tween()
	t.tween_property(node, "modulate:a", 0.0, 0.35)
	t.tween_callback(node.queue_free)


func _add_tooltip_panel() -> void:
	var canvas_layer: CanvasLayer = $CanvasLayer
	_tooltip_panel = Panel.new()
	_tooltip_panel.name = "TooltipPanel"
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 10
	_tooltip_panel.size = Vector2(160, 38)

	var ts := StyleBoxFlat.new()
	ts.bg_color     = Color(0.05, 0.04, 0.12, 0.92)
	ts.border_color = M_OUTLINE
	ts.set_border_width_all(1)
	ts.set_corner_radius_all(6)
	ts.shadow_color = SHADOW_COL
	ts.shadow_size  = 4
	ts.content_margin_left  = 8;  ts.content_margin_right  = 8
	ts.content_margin_top   = 4;  ts.content_margin_bottom = 4
	_tooltip_panel.add_theme_stylebox_override("panel", ts)

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_size_override("font_size", 10)
	_tooltip_label.add_theme_color_override("font_color", M_ON_SURF)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.position = Vector2(8, 4)
	_tooltip_panel.add_child(_tooltip_label)

	canvas_layer.add_child(_tooltip_panel)


func _update_tooltip() -> void:
	if not _tooltip_panel:
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var graph_offset: Vector2 = $GraphLayer.position
	var hovered_id: String = ""
	for dept_id: String in NODE_POSITIONS:
		var node_screen: Vector2 = NODE_POSITIONS[dept_id] + graph_offset
		if abs(mouse.x - node_screen.x) <= 68 and abs(mouse.y - node_screen.y) <= 40:
			hovered_id = dept_id
			break
	if hovered_id.is_empty():
		_tooltip_panel.visible = false
		return
	var dept_node: DepartmentNode = department_node_map.get(hovered_id)
	var state_human: String = "Undiscovered"
	if dept_node:
		match dept_node.get_visual_state():
			"frontier": state_human = "Active / In Queue"
			"visited":  state_human = "Processed / Done"
	_tooltip_label.text = "%s\n%s" % [hovered_id.capitalize(), state_human]
	_tooltip_panel.visible = true
	var vp_size: Vector2 = get_viewport_rect().size
	var tp_pos: Vector2  = mouse + Vector2(14, -40)
	tp_pos.x = clampf(tp_pos.x, 0, vp_size.x - 165)
	tp_pos.y = clampf(tp_pos.y, 0, vp_size.y - 45)
	_tooltip_panel.position = tp_pos
