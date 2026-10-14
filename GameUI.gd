class_name GameUI
extends Control

signal advance_requested
signal reset_requested

const QUEUE_EMPTY_TEXT: String = "[ Empty — enjoy it while it lasts ]"

const ALGORITHM_FORM_CODES: Array[String] = [
	"BFS-9A", "DFS-2B", "TOPO-7K", "DIJ-1138", "BF-404", "MST-42",
	"ASTAR-H1", "FW-INF", "KRU-7F"
]
const ALGORITHM_STRUCTURE_LABELS: Array[String] = [
	">> THE QUEUE:",
	">> THE STACK:",
	">> ZERO-IN-DEGREE QUEUE:",
	">> PRIORITY QUEUE (cost, dept):",
	">> DISTANCES (dept: cost):",
	">> MST CANDIDATES (cost, dept):",
	">> OPEN SET (f=g+h):",
	">> DISTANCES (all nodes->dest):",
	">> EDGE CANDIDATES (sorted):"
]
const ALGORITHM_NAMES: Array[String] = [
	"BFS — Breadth-First Search",
	"DFS — Depth-First Search",
	"Topo Sort — Kahn's Algorithm",
	"Dijkstra — Shortest Path",
	"Bellman-Ford — Shortest Path",
	"Prim's — Min Spanning Tree",
	"A* — Heuristic Search",
	"Floyd-Warshall — All-Pairs",
	"Kruskal's — Min Spanning Tree"
]

const ALGORITHM_INFO: Array[Dictionary] = [
	{
		"how_it_works": (
			"Explores the graph level by level. All departments one hop from the start are " +
			"visited before any two hops away. Every discovered department enters the QUEUE " +
			"before being processed.\n\n" +
			"Guarantees the fewest-hop path to any reachable node — but ignores edge weights entirely."
		),
		"structure_explain": (
			"FIFO — First In, First Out.\n\n" +
			"Departments are processed in the order they were discovered. The oldest entry is " +
			"always at the front. This enforces level-by-level expansion."
		),
		"watch_for": (
			"Watch amber spread outward in rings from 'redundancy'. The entire first ring " +
			"(forms, delays) turns amber before any second-ring node (stamps, lost) is touched.\n\n" +
			"Compare to DFS, which dives deep before spreading wide."
		),
		"complexity": "Time:   O(V + E)\nSpace:  O(V)\n\nVisits each node and edge exactly once."
	},
	{
		"how_it_works": (
			"Commits to one branch and follows it as deep as possible before backtracking. " +
			"Uses a STACK (Last In, First Out) — the most recently discovered node is processed next.\n\n" +
			"Nodes are marked visited when POPPED, not when pushed, so the same node may appear " +
			"in the stack multiple times. Stale copies are discarded when reached."
		),
		"structure_explain": (
			"LIFO — Last In, First Out.\n\n" +
			"The stack is shown top-to-bottom: the top entry is processed next. " +
			"Duplicate entries exist for nodes pushed via multiple paths — stale copies " +
			"produce a 'STALE MEMO INTERCEPTED' message when popped."
		),
		"watch_for": (
			"Watch the algorithm race down the delays → lost → destination corridor " +
			"completely before jumping back to process forms.\n\n" +
			"'STALE MEMO INTERCEPTED' steps are expected — these are outdated stack entries " +
			"being discarded. This is normal DFS behavior, not an error."
		),
		"complexity": "Time: O(V + E)\nSpace: O(V + E) in this iterative demo\n\nDuplicate pending entries can occur because nodes are marked on pop. A recursive DFS uses O(V) auxiliary space."
	},
	{
		"how_it_works": (
			"Orders all departments so no department is processed before its prerequisites " +
			"are cleared. Works only on directed acyclic graphs (no cycles).\n\n" +
			"Kahn's Algorithm tracks in-degree (incoming edge count) per node. Only nodes " +
			"with in-degree 0 may be processed. Processing one node decrements its neighbors' " +
			"in-degrees, potentially unlocking them."
		),
		"structure_explain": (
			"ZERO-IN-DEGREE QUEUE.\n\n" +
			"Holds departments with no remaining unprocessed predecessors. " +
			"As each department is processed, its outgoing edges are 'removed' " +
			"(neighbors' in-degrees decremented). Any neighbor that hits 0 is immediately enqueued."
		),
		"watch_for": (
			"Only 'redundancy' has in-degree 0 at the start — nothing points to it. " +
			"After processing it, both 'forms' and 'delays' are unlocked.\n\n" +
			"Each neighbor's in-degree decrement is shown one at a time. The final memo " +
			"displays the complete topological ordering."
		),
		"complexity": "Time:   O(V + E)\nSpace:  O(V)\n\nEach node and edge processed exactly once."
	},
	{
		"how_it_works": (
			"Finds the lowest-cost path from start to every other node by always processing " +
			"the cheapest unfinalized node next.\n\n" +
			"IMPORTANT: this game converts the -2 edge to +2 (absolute value) because " +
			"Dijkstra is undefined for negative weights and may produce wrong answers. " +
			"For the real -2 result, run Bellman-Ford."
		),
		"structure_explain": (
			"MIN-PRIORITY QUEUE — entries show [cost] — Department.\n\n" +
			"The cheapest entry is extracted first. When a cheaper path is found, " +
			"the old entry is NOT removed — it becomes stale and is discarded when " +
			"eventually extracted. This is called 'lazy deletion'."
		),
		"watch_for": (
			"Nodes are finalized in cost order, not hop order. 'Delays' (cost 1) " +
			"is finalized before 'forms' (cost 3), even though both are one hop away.\n\n" +
			"Watch for 'STALE ENTRY DETECTED' memos — the lazy deletion mechanism in action. " +
			"The final path costs 9 because abs(-2) = 2."
		),
		"complexity": "Standard binary heap: O((V+E) log V)\nSpace: O(V + E) with lazy duplicates\n\nThis teaching demo sorts an array on insertion; its UI steps do not measure the heap bound."
	},
	{
		"how_it_works": (
			"Finds the lowest-cost path by scanning every edge up to |V|−1 = 5 times, " +
			"relaxing distances whenever a cheaper route is found.\n\n" +
			"Unlike Dijkstra, Bellman-Ford handles NEGATIVE weights correctly. " +
			"The -2 edge on forms → lost is used as-is, yielding the true shortest " +
			"path with total cost 5."
		),
		"structure_explain": (
			"DISTANCE TABLE — one row per department.\n\n" +
			"Shows the current best known cost from start to every node. Starts at " +
			"infinity (INF) for all nodes except the start (cost 0). Updated one edge " +
			"relaxation at a time. Early termination fires if a full pass produces no improvements."
		),
		"watch_for": (
			"After Pass 1, all reachable nodes have finite distances. " +
			"Early termination triggers in Pass 2 — no further improvements are possible.\n\n" +
			"The final cost-5 path uses the -2 edge. Compare to Dijkstra's cost-9 — the " +
			"difference is exactly 4, which is 2 - (-2) = 4."
		),
		"complexity": "Time: O(V x E)\nSpace: O(V)\n\nAt most (V-1)E relaxation attempts, plus the negative-cycle check. UI transitions add display steps."
	},
	{
		"how_it_works": (
			"Builds a Minimum Spanning Tree (MST) — a set of edges connecting ALL " +
			"departments with minimum total weight and no cycles.\n\n" +
			"The graph is treated as undirected (edges work both ways). All weights " +
			"use absolute values. Each step adds the cheapest available connection " +
			"to the growing tree."
		),
		"structure_explain": (
			"MIN-PRIORITY QUEUE of MST candidates.\n\n" +
			"Entries show [cost] — Department, where cost is the cheapest known edge " +
			"connecting that node to the current MST. When a better connection is found " +
			"(new MST node offers cheaper edge), a new entry is added and the old becomes stale."
		),
		"watch_for": (
			"Prim's optimizes per-edge cost, not total path cost — so the result " +
			"differs from Dijkstra's shortest-path tree.\n\n" +
			"'Stamps' is added last: once delivery joins the tree, its 1-credit " +
			"connection beats the 8-credit lane from forms. Total MST weight: 11."
		),
		"complexity": "Standard binary heap: O(E log V)\nSpace: O(V + E) with lazy duplicates\n\nThis teaching demo sorts an array on insertion; its UI steps do not measure the heap bound."
	},
	{
		"how_it_works": (
			"Finds the shortest path from start to the destination by combining " +
			"g(n) — actual cost from start — with h(n) — an admissible heuristic " +
			"estimate to the destination.\n\n" +
			"f(n) = g(n) + h(n). The node with the lowest f is always expanded next. " +
			"This game uses a consistent heuristic, so closing a node finalizes its " +
			"optimal cost from the start. Uses abs weights (treats -2 as 2)."
		),
		"structure_explain": (
			"OPEN SET — priority queue ordered by f-score.\n\n" +
			"Entries show [f=N g=M] — Department. Lower f = higher priority. " +
			"When a cheaper path is found, a new entry is added and the old becomes stale " +
			"(lazy deletion). CLOSED nodes (already extracted) are never re-expanded."
		),
		"watch_for": (
			"Watch A* skip 'delays' entirely — its heuristic h=10 makes f=11 even with " +
			"g=1, so 'forms' (f=9) is expanded first.\n\n" +
			"Compare to Dijkstra: both find cost-9 path, but A* never expands 'delays'. " +
			"The heuristic guides the search away from dead ends."
		),
		"complexity": "Consistent heuristic + heap: O((V+E) log V)\nSpace: O(V + E) with lazy duplicates\n\nThis demo sorts an array. Closed nodes need no reopening when the heuristic is consistent."
	},
	{
		"how_it_works": (
			"Computes shortest paths between ALL pairs of nodes in O(V³) time using " +
			"dynamic programming.\n\n" +
			"Each of the V=6 passes considers one intermediate node k. After pass k, " +
			"dist[i][j] = shortest path from i to j using only nodes 0..k as intermediaries.\n\n" +
			"Handles NEGATIVE weights (unlike Dijkstra). Uses the real -2 edge."
		),
		"structure_explain": (
			"DISTANCE TABLE — dist[node][destination] after each k-pass.\n\n" +
			"Shows current best cost from every node to destination. Starts as direct-edge " +
			"distances only. Updates propagate as intermediate nodes are considered. " +
			"INF = not yet reachable via current k-subset."
		),
		"watch_for": (
			"k=1 (via forms): redundancy->lost drops from INF to 1 (using the -2 edge!).\n\n" +
			"k=4 (via lost): redundancy->destination drops from 12 to 5. " +
			"This is the key moment — the negative shortcut is fully utilized.\n\n" +
			"Final redundancy->dest = 5 vs Dijkstra's 9. The difference is exactly 4."
		),
		"complexity": "Time:   O(V³) = O(216) for V=6\nSpace:  O(V²) — the distance matrix\n\nDetects negative cycles if dist[i][i] < 0 after all passes."
	},
	{
		"how_it_works": (
			"Builds a Minimum Spanning Tree by sorting ALL edges globally and " +
			"greedily accepting the cheapest edge that does not create a cycle.\n\n" +
			"Union-Find (with path compression and union by rank) tracks which " +
			"nodes are connected. An edge is rejected if both endpoints are already " +
			"in the same component. Uses abs weights."
		),
		"structure_explain": (
			"REMAINING SORTED EDGE CANDIDATES.\n\n" +
			"Entries show [weight] NodeA | NodeB for edges not yet examined. " +
			"The list shrinks as edges are consumed (accepted or rejected). " +
			"Unlike Prim's local PQ, Kruskal sees the full global sort from the start."
		),
		"watch_for": (
			"Kruskal processes edges globally by weight — it connects stamps to " +
			"destination (weight 1) before connecting forms to redundancy (weight 3), " +
			"even though those nodes are far apart.\n\n" +
			"Compare to Prim's: same MST weight (11), but Prim grows a connected " +
			"subtree from the start while Kruskal may build disconnected fragments first."
		),
		"complexity": "Time:   O(E log E) — dominated by sorting\nSpace:  O(V + E) — Union-Find + edge list\n\nUnion-Find operations are nearly O(1) amortized with path compression."
	}
]

# Mission HUD and reference controls.
signal rewind_requested
signal answer_requested(choice: String)
signal hint_requested
signal menu_requested
signal next_mission_requested
signal fit_requested

var advance_button: Button
var back_button: Button
var play_button: Button
var sidebar: PanelContainer
var footer: PanelContainer
var header: HBoxContainer
var memo_label: Label
var queue_display: Label
var queue_title: Label
var step_label: Label
var score_label: Label
var feedback_label: Label
var question_box: VBoxContainer
var next_button: Button
var hint_button: Button
var progress_bar: ProgressBar
var reference: PanelContainer
var dispatch_title: Label
var _auto_play: bool = false
var _resume_after_answer: bool = false
var _auto_timer: float = 0.0
var _auto_speed: float = 0.85
var _blocked: bool = false
var _complete: bool = false
var _algorithm: int = 0
var _question_options: Array = []
var guidance_label: Label
var _guidance_pending: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_header()
	_build_sidebar()
	_build_footer()
	get_viewport().size_changed.connect(_relayout)
	_relayout()
	_update_guidance()

func _build_header() -> void:
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	add_child(header)
	var menu := BureauTheme.button("< Mission desk")
	menu.pressed.connect(func(): menu_requested.emit())
	header.add_child(menu)
	var names := BureauTheme.column(header, 2)
	names.add_child(BureauTheme.label("INTERGALACTIC BUREAU / FIELD OPERATIONS", 12, BureauTheme.CYAN))
	names.add_child(BureauTheme.label("Misplaced Mail", 25))
	BureauTheme.spacer(header)
	score_label = BureauTheme.label("PRACTICE" if GameState.practice_mode else "0 PTS  /  0 OF 3", 17, BureauTheme.GOLD)
	header.add_child(score_label)

func _build_sidebar() -> void:
	sidebar = PanelContainer.new()
	sidebar.add_theme_stylebox_override("panel", BureauTheme.panel())
	add_child(sidebar)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var content := BureauTheme.column(scroll, 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(BureauTheme.label("MISSION CONTROL", 12, BureauTheme.CYAN))
	content.add_child(BureauTheme.label(ALGORITHM_NAMES[GameState.selected_algorithm], 23, BureauTheme.INK, true))
	content.add_child(BureauTheme.label(MissionSession.RULES[GameState.selected_algorithm], 15, BureauTheme.MUTED, true))
	guidance_label = BureauTheme.label("",14,BureauTheme.CYAN,true)
	content.add_child(guidance_label)
	feedback_label = BureauTheme.label("Szabadon gyakorolhatsz, bármelyik korábbi lépést visszanézheted." if GameState.practice_mode else "Három ellenőrző kérdésnél te választod ki a következő lépést. A válaszaid után megmutatjuk az indokot.", 15, BureauTheme.GOLD, true)
	content.add_child(feedback_label)
	question_box = BureauTheme.column(content, 8)
	question_box.visible = false
	dispatch_title = BureauTheme.label("LATEST DISPATCH", 12, BureauTheme.CYAN)
	content.add_child(dispatch_title)
	memo_label = BureauTheme.label("", 16, BureauTheme.INK, true)
	content.add_child(memo_label)
	queue_title = BureauTheme.label("FRONTIER", 12, BureauTheme.CYAN, true)
	content.add_child(queue_title)
	queue_display = BureauTheme.label("Awaiting your first dispatch.", 15, BureauTheme.MUTED, true)
	content.add_child(queue_display)
	next_button = BureauTheme.button("Next mission >", true)
	next_button.visible = false
	next_button.pressed.connect(func(): next_mission_requested.emit())
	content.add_child(next_button)

func _build_footer() -> void:
	footer = PanelContainer.new()
	footer.add_theme_stylebox_override("panel", BureauTheme.panel())
	add_child(footer)
	var column := BureauTheme.column(footer, 10)
	var controls := BureauTheme.row(column, 10)
	back_button = BureauTheme.button("< Back")
	back_button.visible = GameState.practice_mode
	back_button.pressed.connect(func(): stop_auto(); rewind_requested.emit())
	controls.add_child(back_button)
	advance_button = BureauTheme.button("Send first dispatch  [Space]", true)
	advance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advance_button.pressed.connect(request_advance)
	controls.add_child(advance_button)
	play_button = BureauTheme.button("Auto  [A]")
	play_button.pressed.connect(toggle_auto)
	controls.add_child(play_button)
	var speed := OptionButton.new()
	speed.custom_minimum_size = Vector2(100, 44)
	speed.add_item("Relaxed", 0)
	speed.add_item("Normal", 1)
	speed.add_item("Fast", 2)
	speed.select(1)
	speed.item_selected.connect(func(index: int): _auto_speed = [1.6, 0.85, 0.35][index])
	controls.add_child(speed)
	var reset := BureauTheme.button("Restart  [R]")
	reset.pressed.connect(func(): stop_auto(); reset_requested.emit())
	controls.add_child(reset)
	var info := BureauTheme.button("Guide  [I]")
	info.pressed.connect(toggle_reference)
	controls.add_child(info)
	var lower := BureauTheme.row(column)
	step_label = BureauTheme.label("DISPATCH 0", 12, BureauTheme.MUTED)
	lower.add_child(step_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(140, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", BureauTheme.panel(BureauTheme.BORDER, BureauTheme.BORDER, 0))
	progress_bar.add_theme_stylebox_override("fill", BureauTheme.panel(BureauTheme.CYAN, BureauTheme.CYAN, 0))
	lower.add_child(progress_bar)
	lower.add_child(BureauTheme.label("1 / 2 / 3 choose  |  H hint  |  F fit map", 12, BureauTheme.MUTED))

func _relayout() -> void:
	var view: Vector2 = get_viewport_rect().size
	header.position = Vector2(24, 22)
	header.size = Vector2(view.x - 48, 56)
	sidebar.position = Vector2(view.x - 394, 98)
	sidebar.size = Vector2(370, view.y - 248)
	footer.position = Vector2(24, view.y - 130)
	footer.size = Vector2(view.x - 48, 106)

func configure(index: int) -> void:
	_algorithm = index
	queue_title.text = ALGORITHM_STRUCTURE_LABELS[index].replace(">> ", "")

func update_frame(frame: Dictionary, step: int, total: int) -> void:
	memo_label.text = frame["message"]
	var lines: PackedStringArray = []
	for item: String in frame["structure"]:
		var short_item: String = item
		for id: String in GraphManager.DEPARTMENTS:
			short_item = short_item.replace(GraphManager.DEPARTMENTS[id]["name"], DepartmentNode.SHORT_NAMES[id].capitalize())
		lines.append(short_item)
	queue_display.text = "No departments waiting." if lines.is_empty() else "\n".join(lines)
	step_label.text = "DISPATCH %d / %d" % [step, total]
	progress_bar.max_value = total
	progress_bar.value = step
	_complete = frame["is_complete"]
	advance_button.disabled = _complete
	advance_button.text = "Report delivered" if _complete else "Next dispatch  [Space]"
	play_button.disabled = _complete
	back_button.disabled = step <= 1
	if _complete:
		stop_auto()
	_update_guidance()

func request_advance() -> void:
	if not _blocked and not _complete and not is_reference_open():
		advance_requested.emit()
	else: _update_guidance()

func show_question(question: Dictionary, ordinal: int) -> void:
	var resume: bool = _auto_play
	stop_auto()
	_resume_after_answer = resume
	_blocked = true
	advance_button.disabled = true
	play_button.disabled = true
	_question_options = question["options"]
	_clear_question()
	question_box.visible = true
	question_box.add_child(BureauTheme.label("YOUR CALL  /  CHECKPOINT %d OF 3" % ordinal, 12, BureauTheme.VIOLET))
	question_box.add_child(BureauTheme.label(question["prompt"], 20, BureauTheme.INK, true))
	if question["node_choice"] or _algorithm == 8:
		var context: PackedStringArray = queue_display.text.split("\n")
		question_box.add_child(BureauTheme.label("Frontier: " + " | ".join(context.slice(0, 3)), 14, BureauTheme.MUTED, true))
	_set_dispatch_visible(false)
	for index: int in _question_options.size():
		var choice: String = _question_options[index]
		var button := BureauTheme.button("%d.  %s" % [index + 1, display_choice(choice)])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): answer_requested.emit(choice))
		question_box.add_child(button)
	hint_button = BureauTheme.button("Request hint  [H]  (-25 pts)")
	hint_button.pressed.connect(func(): hint_requested.emit())
	question_box.add_child(hint_button)
	feedback_label.text = "A válaszodra várunk. Válassz lent az 1–3 gombokkal" + (", vagy kattints egy kijelölt állomásra." if question["node_choice"] else ".")
	feedback_label.add_theme_color_override("font_color", BureauTheme.VIOLET)
	_update_guidance()

func _clear_question() -> void:
	for child: Node in question_box.get_children():
		question_box.remove_child(child)
		child.queue_free()

func show_feedback(result: Dictionary, session: MissionSession) -> void:
	_blocked = false
	question_box.visible = false
	_set_dispatch_visible(true)
	advance_button.disabled = _complete
	play_button.disabled = _complete
	feedback_label.text = ("Helyes döntés! +%d pont. " % result["points"] if result["correct"] else "Most %s a helyes folytatás; ezzel léptünk tovább. Olvasd el, miért: " % display_choice(result["answer"])) + result["rule"]
	feedback_label.add_theme_color_override("font_color", BureauTheme.CYAN if result["correct"] else BureauTheme.GOLD)
	score_label.text = "%d PTS  /  %d OF 3" % [session.score, session.answered.size()]
	if _resume_after_answer and not _complete:
		_resume_after_answer = false
		toggle_auto()
	_update_guidance()

func show_hint(text: String) -> void:
	feedback_label.text = text + "  (Ehhez a kérdéshez egyszer számít: helyes válasz esetén −25 pont.)"
	hint_button.disabled = true

func show_completion(session: MissionSession) -> void:
	next_button.visible = true
	if GameState.practice_mode:
		feedback_label.text = "Practice complete. Rewind to review, or try a scored mission from the desk."
	else:
		var medals: Array[String] = ["", "BRONZE", "SILVER", "GOLD"]
		feedback_label.text = "%s MEDAL / %d pts / %d of 3 correct\nDirector Zorp approves your report. Replay for a better medal!" % [medals[session.stars()], session.score, session.correct_count]
		feedback_label.add_theme_color_override("font_color", BureauTheme.GOLD)
	_update_guidance()

func reset_display() -> void:
	stop_auto()
	_blocked = false
	_complete = false
	question_box.visible = false
	_set_dispatch_visible(true)
	next_button.visible = false
	advance_button.disabled = false
	play_button.disabled = false
	advance_button.text = "Send first dispatch  [Space]"
	score_label.text = "PRACTICE" if GameState.practice_mode else "0 PTS  /  0 OF 3"
	progress_bar.value = 0
	step_label.text = "DISPATCH 0"
	queue_display.text = "Awaiting your first dispatch."
	feedback_label.text = "Szabadon gyakorolhatsz. A korábbi lépésekhez vissza is térhetsz." if GameState.practice_mode else "Három döntés következik. Mindhárom helyes válasz segítség nélkül aranyérmet ér."
	_update_guidance()

func _set_dispatch_visible(visible: bool) -> void:
	for item: Control in [dispatch_title, memo_label, queue_title, queue_display]:
		item.visible = visible

func toggle_auto() -> void:
	if _blocked or _complete or is_reference_open():
		_update_guidance()
		return
	_auto_play = not _auto_play
	_auto_timer = 0.0
	play_button.text = "Pause  [A]" if _auto_play else "Auto  [A]"
	_update_guidance()

func stop_auto() -> void:
	_auto_play = false
	_resume_after_answer = false
	_auto_timer = 0.0
	play_button.text = "Auto  [A]"

func _process(delta: float) -> void:
	if _auto_play:
		_auto_timer += delta
		if _auto_timer >= _auto_speed:
			_auto_timer = 0.0
			request_advance()

func is_reference_open() -> bool:
	return is_instance_valid(reference) and reference.visible

func toggle_reference() -> void:
	stop_auto()
	if is_instance_valid(reference):
		reference.visible = not reference.visible
		_update_guidance()
		return
	reference = PanelContainer.new()
	reference.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reference.offset_left = 80
	reference.offset_right = -80
	reference.offset_top = 84
	reference.offset_bottom = -150
	reference.add_theme_stylebox_override("panel", BureauTheme.panel(BureauTheme.SURFACE, BureauTheme.VIOLET, 28))
	add_child(reference)
	_update_guidance()
	var column := BureauTheme.column(reference)
	var top := BureauTheme.row(column)
	top.add_child(BureauTheme.label(ALGORITHM_NAMES[_algorithm], 26))
	BureauTheme.spacer(top)
	var close := BureauTheme.button("Close  [I / Esc]")
	close.pressed.connect(func(): reference.hide(); _update_guidance())
	top.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := BureauTheme.column(scroll, 20)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info: Dictionary = ALGORITHM_INFO[_algorithm]
	for field: String in ["how_it_works", "structure_explain", "watch_for", "complexity"]:
		body.add_child(BureauTheme.label(field.replace("_", " ").to_upper(), 13, BureauTheme.CYAN))
		body.add_child(BureauTheme.label(info[field], 18, BureauTheme.INK, true))
	body.add_child(BureauTheme.label("MAP: amber = waiting / cyan = processed / violet = a possible answer.\nSpace advances; A toggles auto; R restarts; Left rewinds in practice.\nMission scores persist locally. Hints cost 25 pts on a correct answer; wrong answers reset your streak.", 16, BureauTheme.MUTED, true))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_reference_open():
		if event.keycode in [KEY_ESCAPE, KEY_I]:
			reference.hide()
			_update_guidance()
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_SPACE: request_advance()
		KEY_A: toggle_auto()
		KEY_R: stop_auto(); reset_requested.emit()
		KEY_I: toggle_reference()
		KEY_F: fit_requested.emit()
		KEY_ESCAPE: menu_requested.emit()
		KEY_LEFT:
			if GameState.practice_mode:
				stop_auto()
				rewind_requested.emit()
		KEY_H:
			if _blocked: hint_requested.emit()
		KEY_1, KEY_2, KEY_3:
			if _blocked:
				answer_requested.emit(_question_options[event.keycode - KEY_1])
		_: return
	get_viewport().set_input_as_handled()

func _update_guidance() -> void:
	if _guidance_pending: return
	_guidance_pending = true
	_refresh_guidance.call_deferred()

func _refresh_guidance() -> void:
	_guidance_pending = false
	if not is_inside_tree(): return
	if not is_instance_valid(guidance_label): return
	if is_reference_open():
		_set_guidance("A labor szünetel, amíg olvasol","A gráf állapota nem változik a magyarázat olvasása közben.","Esc vagy I: vissza a feladathoz. A: automata újraindítása.")
	elif _complete:
		_set_guidance("Elkészült a jelentés!","A gyakorlás véget ért; a korábbi lépéseket továbbra is visszanézheted." if GameState.practice_mode else "A három döntésed eredményét és a megszerzett pontokat a jelentésben találod.","Következő küldetés: új téma. Restart [R]: ugyanennek a feladatnak az újrakezdése.")
	elif _blocked:
		_set_guidance("Most a válaszodra várunk","Az automata itt megvárja a döntésedet; válaszadás után magától folytatódik." if _resume_after_answer else "Válaszd ki a szerinted helyes következő lépést. Hibánál is elmagyarázzuk az eredményt.","Válassz 1, 2 vagy 3-mal. H: segítség, amely egyszer csökkenti a helyes válaszért járó pontot.")
	elif _auto_play:
		_set_guidance("Automata fut — figyeld a változásokat","A lépések a kiválasztott sebességgel követik egymást. A pontozott küldetés kérdéseinél megállunk.","A: szünet. I: részletes magyarázat. A sebesség a lejátszógomb mellett állítható.")
	else:
		_set_guidance("Te következel — nincs időnyomás","Nézd meg az aktuális állapotot és a várakozó elemeket. A következő lépés után megmutatjuk, mi változott.","Space vagy Next dispatch: egy lépés. A: automata. I: magyarázat.")

func _set_guidance(title: String, message: String, next: String) -> void:
	guidance_label.text = title + "\n" + message + "\n" + next

static func display_choice(choice: String) -> String:
	if choice.contains("|"):
		var parts := choice.split("|")
		return "%s - %s" % [parts[0].capitalize(), parts[1].capitalize()]
	if DepartmentNode.SHORT_NAMES.has(choice):
		return DepartmentNode.SHORT_NAMES[choice].capitalize()
	return choice
