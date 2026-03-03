class_name MenuScene
extends Node2D

const CARD_DATA: Array[Dictionary] = [
	{
		"short": "BFS",
		"full": "Breadth-First Search",
		"complexity": "O(V + E)",
		"desc": "Explores ring by ring from the start. Guarantees the fewest-hop path to every node.",
		"insight": "Perfect for finding the shortest unweighted route — used in GPS, social networks, and maze solvers.",
		"difficulty": 1,
		"category": "TRAVERSAL",
		"cat_color": Color(0.40, 0.70, 1.00)
	},
	{
		"short": "DFS",
		"full": "Depth-First Search",
		"complexity": "O(V + E)",
		"desc": "Commits to one path and dives as deep as possible before backtracking. Uses a LIFO stack.",
		"insight": "Foundation of cycle detection, topological sort, and maze generation. Often faster in practice than BFS.",
		"difficulty": 1,
		"category": "TRAVERSAL",
		"cat_color": Color(0.40, 0.70, 1.00)
	},
	{
		"short": "Topo Sort",
		"full": "Kahn's Algorithm",
		"complexity": "O(V + E)",
		"desc": "Orders nodes so every dependency comes before its dependents. Only works on acyclic graphs.",
		"insight": "Powers build systems, task schedulers, and package managers. If a cycle is found, it reports an error.",
		"difficulty": 2,
		"category": "ORDERING",
		"cat_color": Color(0.80, 0.40, 1.00)
	},
	{
		"short": "Dijkstra",
		"full": "Shortest Path",
		"complexity": "O(V²)",
		"desc": "Finds the lowest-cost path by always expanding the cheapest unfinished node. No negative edges.",
		"insight": "The backbone of routing protocols and navigation apps. Negative edges break it — use Bellman-Ford instead.",
		"difficulty": 2,
		"category": "SHORTEST PATH",
		"cat_color": Color(1.00, 0.65, 0.00)
	},
	{
		"short": "Bellman-Ford",
		"full": "Shortest Path (Negative Edges)",
		"complexity": "O(V · E)",
		"desc": "Relaxes every edge up to V-1 times. Handles negative weights and detects negative cycles.",
		"insight": "Slower than Dijkstra but more powerful. Used in BGP internet routing where negative-cost links exist.",
		"difficulty": 3,
		"category": "SHORTEST PATH",
		"cat_color": Color(1.00, 0.65, 0.00)
	},
	{
		"short": "Prim's MST",
		"full": "Minimum Spanning Tree",
		"complexity": "O(V²)",
		"desc": "Connects every node with the minimum total edge cost. No cycles, no disconnected nodes.",
		"insight": "Used in network design, power grids, and clustering. Optimizes total connection cost, not individual paths.",
		"difficulty": 3,
		"category": "SPANNING TREE",
		"cat_color": Color(0.30, 0.85, 0.55)
	},
	{
		"short": "A*",
		"full": "A* Search",
		"complexity": "O(V²)",
		"desc": "Guided shortest-path search. Combines actual cost g(n) with heuristic estimate h(n). Expands fewer nodes than Dijkstra.",
		"insight": "Powers game pathfinding and GPS routing. The heuristic skips dead ends — here it avoids 'delays' entirely.",
		"difficulty": 3,
		"category": "HEURISTIC SEARCH",
		"cat_color": Color(0.90, 0.30, 0.60)
	},
	{
		"short": "F-W",
		"full": "Floyd-Warshall",
		"complexity": "O(V³)",
		"desc": "Computes shortest paths between ALL pairs of nodes in 6 passes. Handles negative weights correctly.",
		"insight": "Used in network routing tables. The only algorithm here that finds redundancy->destination = 5 using the real -2 edge.",
		"difficulty": 3,
		"category": "ALL-PAIRS PATH",
		"cat_color": Color(0.20, 0.80, 1.00)
	},
	{
		"short": "Kruskal",
		"full": "Kruskal's MST",
		"complexity": "O(E log E)",
		"desc": "Builds MST by sorting all edges globally and accepting the cheapest non-cycle edge. Uses Union-Find.",
		"insight": "Compare to Prim's: same MST weight (11), but Kruskal connects across the graph while Prim grows locally.",
		"difficulty": 2,
		"category": "SPANNING TREE",
		"cat_color": Color(0.30, 0.85, 0.55)
	},
]

# Galaxy / Nebula Palette
const M_BG:          Color = Color(0.03, 0.02, 0.08)
const M_SURFACE:     Color = Color(0.07, 0.05, 0.13)
const M_SURFACE_V:   Color = Color(0.12, 0.09, 0.22)
const M_PRIMARY:     Color = Color(0.52, 0.32, 1.00)
const M_PRIMARY_C:   Color = Color(0.15, 0.09, 0.36)
const M_SECONDARY:   Color = Color(0.08, 0.88, 0.82)
const M_SECONDARY_C: Color = Color(0.02, 0.20, 0.18)
const M_ON_SURF:     Color = Color(0.93, 0.90, 1.00)
const M_ON_SURF_V:   Color = Color(0.57, 0.52, 0.75)
const M_OUTLINE:     Color = Color(0.20, 0.16, 0.38)
const M_OUTLINE_V:   Color = Color(0.38, 0.32, 0.62)
const SHADOW_COL:    Color = Color(0.00, 0.00, 0.08, 0.70)
const DIFF_FILLED:   Color = Color(1.00, 0.72, 0.12)
const DIFF_EMPTY:    Color = Color(0.22, 0.18, 0.38)

const RADIUS_CARD: int = 12
const RADIUS_CHIP: int = 20


func _ready() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# ── Deep space background ──────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = M_BG
	canvas.add_child(bg)

	# Nebula glow — top-centre radial tint
	var nebula_top := ColorRect.new()
	nebula_top.color         = Color(0.18, 0.06, 0.38, 0.18)
	nebula_top.anchor_left   = 0.15
	nebula_top.anchor_top    = 0.0
	nebula_top.anchor_right  = 0.85
	nebula_top.anchor_bottom = 0.45
	canvas.add_child(nebula_top)

	# Nebula glow — bottom-right accent
	var nebula_br := ColorRect.new()
	nebula_br.color         = Color(0.02, 0.20, 0.22, 0.14)
	nebula_br.anchor_left   = 0.55
	nebula_br.anchor_top    = 0.55
	nebula_br.anchor_right  = 1.0
	nebula_br.anchor_bottom = 1.0
	canvas.add_child(nebula_br)

	# ── Root layout ───────────────────────────────────────────────────────────
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left",   48)
	root_margin.add_theme_constant_override("margin_right",  48)
	root_margin.add_theme_constant_override("margin_top",    28)
	root_margin.add_theme_constant_override("margin_bottom", 28)
	canvas.add_child(root_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	root_margin.add_child(vbox)

	# ── Title block ───────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "INTERGALACTIC BUREAU OF MISPLACED MAIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", M_ON_SURF)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_shadow_color",
			Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.55))
	title.add_theme_constant_override("shadow_outline_size", 6)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Graph Algorithm Visualizer"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", M_SECONDARY)
	subtitle.add_theme_font_size_override("font_size", 13)
	vbox.add_child(subtitle)

	# ── About This Game panel ─────────────────────────────────────────────────
	var about_panel := PanelContainer.new()
	var about_style := StyleBoxFlat.new()
	about_style.bg_color     = Color(0.08, 0.06, 0.18, 0.80)
	about_style.border_color = M_PRIMARY
	about_style.set_border_width_all(1)
	about_style.set_corner_radius_all(RADIUS_CARD)
	about_style.shadow_color = SHADOW_COL
	about_style.shadow_size  = 8
	about_panel.add_theme_stylebox_override("panel", about_style)
	vbox.add_child(about_panel)

	var about_margin := MarginContainer.new()
	about_margin.add_theme_constant_override("margin_left",   18)
	about_margin.add_theme_constant_override("margin_right",  18)
	about_margin.add_theme_constant_override("margin_top",    12)
	about_margin.add_theme_constant_override("margin_bottom", 12)
	about_panel.add_child(about_margin)

	var about_hbox := HBoxContainer.new()
	about_hbox.add_theme_constant_override("separation", 28)
	about_margin.add_child(about_hbox)

	# Left: what is this
	var what_col := VBoxContainer.new()
	what_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	what_col.add_theme_constant_override("separation", 4)
	about_hbox.add_child(what_col)

	var what_title := Label.new()
	what_title.text = "WHAT IS THIS?"
	what_title.add_theme_color_override("font_color", M_SECONDARY)
	what_title.add_theme_font_size_override("font_size", 10)
	what_col.add_child(what_title)

	var what_body := Label.new()
	what_body.text = (
		"A package is lost somewhere in the Intergalactic Bureau. " +
		"Different routing algorithms search for it in completely different ways — " +
		"some explore wide, some dive deep, some weigh costs.\n\n" +
		"Each step shows exactly what the algorithm is thinking. " +
		"Read the memo, watch the nodes light up, and learn why each strategy works."
	)
	what_body.add_theme_color_override("font_color", M_ON_SURF_V)
	what_body.add_theme_font_size_override("font_size", 11)
	what_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	what_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	what_col.add_child(what_body)

	# Right: how to play
	var how_col := VBoxContainer.new()
	how_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_col.add_theme_constant_override("separation", 4)
	about_hbox.add_child(how_col)

	var how_title := Label.new()
	how_title.text = "HOW TO PLAY"
	how_title.add_theme_color_override("font_color", M_SECONDARY)
	how_title.add_theme_font_size_override("font_size", 10)
	how_col.add_child(how_title)

	var steps: Array[Array] = [
		["1", "Select an algorithm card below."],
		["2", "Press  \"Process Next Memo\"  to advance one step."],
		["3", "Read the memo — it explains every decision."],
		["4", "Drag the graph to pan.  Click [i] Info for deep details."],
		["5", "Press Reset to restart anytime."],
	]
	for step: Array in steps:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		how_col.add_child(row)

		var num := Label.new()
		num.text = step[0]
		num.custom_minimum_size = Vector2(14, 0)
		num.add_theme_color_override("font_color", M_PRIMARY)
		num.add_theme_font_size_override("font_size", 11)
		row.add_child(num)

		var txt := Label.new()
		txt.text = step[1]
		txt.add_theme_color_override("font_color", M_ON_SURF_V)
		txt.add_theme_font_size_override("font_size", 11)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(txt)

	# ── Separator + label ─────────────────────────────────────────────────────
	var grid_label_row := HBoxContainer.new()
	grid_label_row.add_theme_constant_override("separation", 12)
	vbox.add_child(grid_label_row)

	var grid_lbl := Label.new()
	grid_lbl.text = "SELECT AN ALGORITHM"
	grid_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	grid_lbl.add_theme_font_size_override("font_size", 11)
	grid_label_row.add_child(grid_lbl)

	var sep_line := HSeparator.new()
	sep_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = M_OUTLINE
	sep_style.set_content_margin_all(1.0)
	sep_line.add_theme_stylebox_override("separator", sep_style)
	sep_line.add_theme_constant_override("separation", 1)
	grid_label_row.add_child(sep_line)

	# ── Algorithm card grid ───────────────────────────────────────────────────
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	for i: int in CARD_DATA.size():
		_build_card(grid, i)

	# ── Footer ────────────────────────────────────────────────────────────────
	var footer := Label.new()
	footer.text = "Tip: click [i] Info in-game for a full algorithm reference, complexity analysis, and color guide."
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(M_ON_SURF_V.r, M_ON_SURF_V.g, M_ON_SURF_V.b, 0.60))
	footer.add_theme_font_size_override("font_size", 10)
	vbox.add_child(footer)


func _build_card(parent: GridContainer, idx: int) -> void:
	var data: Dictionary      = CARD_DATA[idx]
	var cat_color: Color      = data["cat_color"]
	var difficulty: int       = data["difficulty"]

	var card_normal := StyleBoxFlat.new()
	card_normal.bg_color     = M_SURFACE
	card_normal.border_color = M_OUTLINE
	card_normal.set_border_width_all(1)
	card_normal.set_corner_radius_all(RADIUS_CARD)
	card_normal.shadow_color  = SHADOW_COL
	card_normal.shadow_size   = 5
	card_normal.shadow_offset = Vector2(0, 2)
	card_normal.set_content_margin_all(0)

	var card_hover := StyleBoxFlat.new()
	card_hover.bg_color     = M_SURFACE_V
	card_hover.border_color = M_OUTLINE_V
	card_hover.set_border_width_all(1)
	card_hover.set_corner_radius_all(RADIUS_CARD)
	card_hover.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.40)
	card_hover.shadow_size   = 14
	card_hover.shadow_offset = Vector2(0, 4)
	card_hover.set_content_margin_all(0)

	var panel := PanelContainer.new()
	panel.custom_minimum_size  = Vector2(0, 148)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", card_normal)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(inner)

	# TopRow: short name + category chip
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(top_row)

	var short_lbl := Label.new()
	short_lbl.text = data["short"]
	short_lbl.add_theme_color_override("font_color", M_ON_SURF)
	short_lbl.add_theme_font_size_override("font_size", 20)
	short_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	short_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_row.add_child(short_lbl)

	# Category chip
	var cat_chip := PanelContainer.new()
	var ccs := StyleBoxFlat.new()
	ccs.bg_color     = Color(cat_color.r, cat_color.g, cat_color.b, 0.15)
	ccs.border_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.55)
	ccs.set_border_width_all(1)
	ccs.set_corner_radius_all(RADIUS_CHIP)
	ccs.content_margin_left  = 8;  ccs.content_margin_right  = 8
	ccs.content_margin_top   = 3;  ccs.content_margin_bottom = 3
	cat_chip.add_theme_stylebox_override("panel", ccs)
	cat_chip.mouse_filter = Control.MOUSE_FILTER_PASS
	var cat_lbl := Label.new()
	cat_lbl.text = data["category"]
	cat_lbl.add_theme_color_override("font_color", cat_color)
	cat_lbl.add_theme_font_size_override("font_size", 8)
	cat_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	cat_chip.add_child(cat_lbl)
	top_row.add_child(cat_chip)

	# Full name
	var full_lbl := Label.new()
	full_lbl.text = data["full"]
	full_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	full_lbl.add_theme_font_size_override("font_size", 11)
	full_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(full_lbl)

	# Difficulty row
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 3)
	diff_row.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(diff_row)

	for s: int in 3:
		var star_lbl := Label.new()
		star_lbl.text = "*"
		star_lbl.add_theme_font_size_override("font_size", 11)
		star_lbl.add_theme_color_override("font_color",
				DIFF_FILLED if s < difficulty else DIFF_EMPTY)
		star_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		diff_row.add_child(star_lbl)

	var diff_spacer := Control.new()
	diff_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_row.add_child(diff_spacer)

	var diff_texts: Array[String] = ["EASY", "MEDIUM", "HARD"]
	var diff_lbl := Label.new()
	diff_lbl.text = diff_texts[difficulty - 1]
	diff_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	diff_lbl.add_theme_font_size_override("font_size", 9)
	diff_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	diff_row.add_child(diff_lbl)

	# Separator
	var mini_sep := HSeparator.new()
	var mss := StyleBoxFlat.new()
	mss.bg_color = M_OUTLINE
	mss.set_content_margin_all(0.5)
	mini_sep.add_theme_stylebox_override("separator", mss)
	mini_sep.add_theme_constant_override("separation", 3)
	mini_sep.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(mini_sep)

	# Complexity + description
	var complexity_lbl := Label.new()
	complexity_lbl.text = data["complexity"]
	complexity_lbl.add_theme_color_override("font_color", M_SECONDARY)
	complexity_lbl.add_theme_font_size_override("font_size", 10)
	complexity_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(complexity_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_color_override("font_color", M_ON_SURF_V)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(desc_lbl)

	# Insight line (italic/dim)
	var insight_lbl := Label.new()
	insight_lbl.text = data["insight"]
	insight_lbl.add_theme_color_override("font_color",
			Color(cat_color.r, cat_color.g, cat_color.b, 0.70))
	insight_lbl.add_theme_font_size_override("font_size", 10)
	insight_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	insight_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insight_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(insight_lbl)

	# Mouse interactions
	panel.mouse_entered.connect(
		func(): panel.add_theme_stylebox_override("panel", card_hover)
	)
	panel.mouse_exited.connect(
		func(): panel.add_theme_stylebox_override("panel", card_normal)
	)
	panel.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton \
					and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				GameState.selected_algorithm = idx
				get_tree().change_scene_to_file("res://Main.tscn")
	)
