class_name LabMenu
extends Control

const CARD_DATA: Array[Dictionary] = [
	{
		"short": "BFS",
		"full": "Breadth-First Search",
		"complexity": "O(V + E)",
		"desc": "Explore layer by layer. Find routes with the fewest hops.",
		"insight": "Perfect for finding the shortest unweighted route — used in GPS, social networks, and maze solvers.",
		"difficulty": 1,
		"category": "TRAVERSAL",
		"cat_color": Color(0.40, 0.70, 1.00)
	},
	{
		"short": "DFS",
		"full": "Depth-First Search",
		"complexity": "O(V + E)",
		"desc": "Dive deep, then backtrack. The newest stack entry goes first.",
		"insight": "Foundation of cycle detection, topological sort, and maze generation. Often faster in practice than BFS.",
		"difficulty": 1,
		"category": "TRAVERSAL",
		"cat_color": Color(0.40, 0.70, 1.00)
	},
	{
		"short": "Topo Sort",
		"full": "Kahn's Algorithm",
		"complexity": "O(V + E)",
		"desc": "Release each department once its prerequisites are complete.",
		"insight": "Powers build systems, task schedulers, and package managers. If a cycle is found, it reports an error.",
		"difficulty": 2,
		"category": "ORDERING",
		"cat_color": Color(0.80, 0.40, 1.00)
	},
	{
		"short": "Dijkstra",
		"full": "Shortest Path",
		"complexity": "O(V²)",
		"desc": "Follow the cheapest unfinished route. Uses absolute lane costs.",
		"insight": "The backbone of routing protocols and navigation apps. Negative edges break it — use Bellman-Ford instead.",
		"difficulty": 2,
		"category": "SHORTEST PATH",
		"cat_color": Color(1.00, 0.65, 0.00)
	},
	{
		"short": "Bellman-Ford",
		"full": "Shortest Path (Negative Edges)",
		"complexity": "O(V · E)",
		"desc": "Find the cheapest route, even with negative credit rebates.",
		"insight": "Slower than Dijkstra but more powerful. Used in BGP internet routing where negative-cost links exist.",
		"difficulty": 3,
		"category": "SHORTEST PATH",
		"cat_color": Color(1.00, 0.65, 0.00)
	},
	{
		"short": "Prim's MST",
		"full": "Minimum Spanning Tree",
		"complexity": "O(V²)",
		"desc": "Grow one connected network with the cheapest new links.",
		"insight": "Used in network design, power grids, and clustering. Optimizes total connection cost, not individual paths.",
		"difficulty": 3,
		"category": "SPANNING TREE",
		"cat_color": Color(0.30, 0.85, 0.55)
	},
	{
		"short": "A*",
		"full": "A* Search",
		"complexity": "O(V²)",
		"desc": "Use cost plus a goal estimate to reach delivery sooner.",
		"insight": "Powers game pathfinding and GPS routing. The heuristic skips dead ends — here it avoids 'delays' entirely.",
		"difficulty": 3,
		"category": "HEURISTIC SEARCH",
		"cat_color": Color(0.90, 0.30, 0.60)
	},
	{
		"short": "F-W",
		"full": "Floyd-Warshall",
		"complexity": "O(V³)",
		"desc": "Solve every source/target pair by trying departments as relays.",
		"insight": "Used in network routing tables. Like Bellman-Ford, finds cost 5 with the original -2 rebate; computes all pairs too.",
		"difficulty": 3,
		"category": "ALL-PAIRS PATH",
		"cat_color": Color(0.20, 0.80, 1.00)
	},
	{
		"short": "Kruskal",
		"full": "Kruskal's MST",
		"complexity": "O(E log E)",
		"desc": "Sort lanes by cost. Join separate components without cycles.",
		"insight": "Compare to Prim's: same MST weight (11), but Kruskal connects across the graph while Prim grows locally.",
		"difficulty": 2,
		"category": "SPANNING TREE",
		"cat_color": Color(0.30, 0.85, 0.55)
	},
]

# Galaxy / Nebula Palette
var _grid: GridContainer
var _stats: Label
var _mode_button: Button
var _mission_button: Button
var _root: Control
var _content: VBoxContainer

func _ready() -> void:
	BureauTheme.apply_theme(self)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var background := BureauBackdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_root.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_content = BureauTheme.column(scroll, 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := BureauTheme.row(_content)
	top.add_child(BureauTheme.label("IBMM  /  GALACTIC POSTAL SERVICE", 13, BureauTheme.CYAN))
	BureauTheme.spacer(top)
	_stats = BureauTheme.label("", 14, BureauTheme.GOLD)
	_update_stats()
	top.add_child(_stats)
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", BureauTheme.panel(Color("192441"), BureauTheme.BORDER, 16))
	_content.add_child(hero)
	var hero_row := BureauTheme.row(hero, 32)
	var hero_text := BureauTheme.column(hero_row, 8)
	hero_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hero_text.add_child(BureauTheme.label("Misplaced Mail", 36))
	hero_text.add_child(BureauTheme.label("One missing parcel. Nine ways to find it.", 20, BureauTheme.INK, true))
	hero_text.add_child(BureauTheme.label("Read the frontier. Make the call. Outsmart the bureaucracy.\nThree decisions per mission, zero time pressure.", 15, BureauTheme.MUTED, true))
	var actions := BureauTheme.column(hero_row, 8)
	actions.custom_minimum_size.x = 260
	actions.add_child(BureauTheme.label("READY FOR YOUR NEXT SHIFT?", 12, BureauTheme.CYAN))
	_mission_button = BureauTheme.button("Continue: " + CARD_DATA[GameState.recommended_algorithm()]["short"], true)
	_mission_button.pressed.connect(func(): _start(GameState.recommended_algorithm()))
	actions.add_child(_mission_button)
	var daily := BureauTheme.button("Today's assignment: " + CARD_DATA[GameState.daily_algorithm()]["short"])
	daily.pressed.connect(func(): _start(GameState.daily_algorithm()))
	actions.add_child(daily)
	actions.add_child(BureauTheme.label("Local saves. Replay to improve.", 12, BureauTheme.MUTED, true))
	var toolbar := BureauTheme.row(_content)
	toolbar.add_child(BureauTheme.label("CHOOSE YOUR MISSION", 15, BureauTheme.CYAN))
	BureauTheme.spacer(toolbar)
	_mode_button = BureauTheme.button("")
	_update_mode()
	_mode_button.pressed.connect(func(): GameState.practice_mode = not GameState.practice_mode; _update_mode())
	toolbar.add_child(_mode_button)
	var sound := BureauTheme.button("Sound: on" if GameState.sound_enabled else "Sound: off")
	sound.pressed.connect(func(): GameState.sound_enabled = not GameState.sound_enabled; sound.text = "Sound: on" if GameState.sound_enabled else "Sound: off"; GameState.save_progress())
	toolbar.add_child(sound)
	var motion := BureauTheme.button("Motion: reduced" if GameState.reduced_motion else "Motion: full")
	motion.pressed.connect(func(): GameState.reduced_motion = not GameState.reduced_motion; motion.text = "Motion: reduced" if GameState.reduced_motion else "Motion: full"; GameState.save_progress())
	toolbar.add_child(motion)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_content.add_child(_grid)
	for index: int in CARD_DATA.size():
		_build_card(index)
	_content.add_child(BureauTheme.label("HOW TO PLAY  /  Advance with Space. Predict with 1, 2, 3 or click a department. H requests a hint.\nPractice mode adds rewind and auto-play. Every algorithm is available from the start.", 14, BureauTheme.MUTED, true))
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	_grid.columns = 2 if get_viewport_rect().size.x < 1100 else 3

func _update_stats() -> void:
	_stats.text = "%d / 9 DELIVERED   |   %d XP" % [GameState.medals.size(), GameState.total_xp()]

func _update_mode() -> void:
	_mode_button.text = "Mode: practice" if GameState.practice_mode else "Mode: missions"

func _build_card(index: int) -> void:
	var data: Dictionary = CARD_DATA[index]
	var button := BureauTheme.button("")
	button.custom_minimum_size = Vector2(280, 160)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = data["insight"]
	button.accessibility_name = data["full"] + " mission"
	button.pressed.connect(func(): _start(index))
	_grid.add_child(button)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 18
	margin.offset_right = -18
	margin.offset_top = 14
	margin.offset_bottom = -14
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var content := BureauTheme.column(margin, 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := BureauTheme.row(content)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(BureauTheme.label("%02d / %s" % [index + 1, data["category"]], 11, data["cat_color"]))
	BureauTheme.spacer(top).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var earned: int = GameState.medals.get(index, 0)
	top.add_child(BureauTheme.label("*".repeat(earned) + ".".repeat(3 - earned), 15, BureauTheme.GOLD))
	content.add_child(BureauTheme.label(data["short"], 25))
	content.add_child(BureauTheme.label(data["desc"], 14, BureauTheme.MUTED, true))
	var bottom := BureauTheme.row(content)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(BureauTheme.label(["EASY", "MEDIUM", "HARD"][data["difficulty"] - 1] + "  /  " + data["complexity"], 12, BureauTheme.CYAN))
	BureauTheme.spacer(bottom).mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(BureauTheme.label("%d PTS" % GameState.best_scores[index] if GameState.best_scores.has(index) else "START >", 12, BureauTheme.GOLD))

func _start(index: int) -> void:
	GameState.selected_algorithm = index
	get_tree().change_scene_to_file("res://Main.tscn")
