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

# Galactic ASCII art — one per algorithm, shown on the intro screen.
const ALGORITHM_ASCII_ART: Array[String] = [
	# ── BFS ──────────────────────────────────────────────────
	"       .  COMMAND HQ  .        \n" +
	"      -~~  [REDUNDANCY] ~~-    \n" +
	"     ~      /         \    ~   \n" +
	"    ~   [FORMS]    [DELAYS]  ~ \n" +
	"    ~    /    \        \     ~ \n" +
	"     ~ [STAMPS][LOST]   ...  ~ \n" +
	"      ~~~      \       ~~~     \n" +
	"           [DESTINATION]       \n" +
	"                               \n" +
	"  Level 1 explored COMPLETELY  \n" +
	"  before any Level 2 node!     ",

	# ── DFS ──────────────────────────────────────────────────
	"  PROBE DIVES DEEP FIRST:      \n" +
	"                               \n" +
	"  [REDUNDANCY]                 \n" +
	"    |                          \n" +
	"    +-->> [DELAYS] >>>         \n" +
	"            |                  \n" +
	"            +-->> [LOST] >>>   \n" +
	"                    |          \n" +
	"                    +-->> [DESTINATION]\n" +
	"            <<-- backtrack     \n" +
	"    <<-- backtrack             \n" +
	"    +-->> [FORMS] >>> ...      ",

	# ── Topo Sort ────────────────────────────────────────────
	"  GALACTIC SUPPLY CHAIN LAW:   \n" +
	"                               \n" +
	"  [REDUNDANCY]  <- in-degree 0 \n" +
	"    /         \                \n" +
	"  [FORMS]   [DELAYS]           \n" +
	"   /    \       \              \n" +
	"[STAMPS][LOST] [LOST]          \n" +
	"    \    /                     \n" +
	"  [DESTINATION]                \n" +
	"                               \n" +
	"  No dept ships its memos      \n" +
	"  before its in-box is clear!  ",

	# ── Dijkstra ─────────────────────────────────────────────
	"  *** GALACTIC GPS v9000 ***   \n" +
	"                               \n" +
	"  Always expand min-cost next: \n" +
	"  cost  1: DELAYS   << first   \n" +
	"  cost  3: FORMS    << second  \n" +
	"  cost  5: LOST     << third   \n" +
	"  cost  9: DESTINATION << done \n" +
	"                               \n" +
	"  WARNING: negative warp lanes \n" +
	"  not supported! abs(-2) = 2   \n" +
	"  Use Bellman-Ford for -2 edge.",

	# ── Bellman-Ford ─────────────────────────────────────────
	"  BUREAUCRATIC MEMO RELAY:     \n" +
	"                               \n" +
	"  PASS 1: relax all 7 edges... \n" +
	"    distances updated!         \n" +
	"  PASS 2: relax all 7 edges... \n" +
	"    no changes! STOP EARLY!    \n" +
	"                               \n" +
	"  NEGATIVE WARP DETECTED:      \n" +
	"  FORMS -> LOST = -2           \n" +
	"  True shortest path cost: 5   \n" +
	"  (Dijkstra would say 9!)      ",

	# ── Prim's MST ───────────────────────────────────────────
	"  GROW THE GALACTIC NETWORK:   \n" +
	"                               \n" +
	"  [REDUNDANCY*]--1--[DELAYS*]  \n" +
	"       |                       \n" +
	"       3                       \n" +
	"       |                       \n" +
	"   [FORMS*]--2--[LOST*]        \n" +
	"                   |           \n" +
	"                   4           \n" +
	"                   |           \n" +
	"             [DESTINATION*]    \n" +
	"  [STAMPS] added last (cost 8) ",

	# ── A* ───────────────────────────────────────────────────
	"  HEURISTIC GUIDANCE SYSTEM:   \n" +
	"                               \n" +
	"  f(n) = g(n) + h(n)           \n" +
	"  g = actual cost from start   \n" +
	"  h = estimated cost to goal   \n" +
	"                               \n" +
	"  DELAYS:  f = 1 + 10 = 11     \n" +
	"  FORMS:   f = 3 +  6 =  9 << \n" +
	"  FORMS wins! DELAYS skipped!  \n" +
	"                               \n" +
	"  The Force(heuristic) guides  \n" +
	"  us away from dead ends!      ",

	# ── Floyd-Warshall ───────────────────────────────────────
	"  ALL-PAIRS DISTANCE MATRIX:   \n" +
	"                               \n" +
	"  k=0: direct edges only       \n" +
	"  k=1: via REDUNDANCY          \n" +
	"  k=2: via FORMS               \n" +
	"    RED->LOST: INF -> 1 (!)    \n" +
	"  k=3: via DELAYS              \n" +
	"  k=4: via LOST                \n" +
	"    RED->DEST: 12  -> 5 (!)    \n" +
	"  k=5: via STAMPS (no change)  \n" +
	"                               \n" +
	"  O(V^3) = 6*6*6 = 216 steps   ",

	# ── Kruskal's ────────────────────────────────────────────
	"  SORTED EDGE MANIFEST:        \n" +
	"                               \n" +
	"  (1) RED  <-> DELAYS   KEEP   \n" +
	"  (1) STAMP <-> DEST    KEEP   \n" +
	"  (2) FORMS <-> LOST    KEEP   \n" +
	"  (3) RED  <-> FORMS    KEEP   \n" +
	"  (4) LOST <-> DEST     KEEP   \n" +
	"  (6) DELAY <-> LOST    SKIP!  \n" +
	"  (8) FORMS <-> STAMP   SKIP!  \n" +
	"                               \n" +
	"  MST weight: 11               \n" +
	"  Same tree as Prim's!         ",
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
		"complexity": "Time:   O(V + E)\nSpace:  O(V)\n\nVisits each node and edge exactly once."
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
		"complexity": "Time:   O(V² ) — sorted array PQ\nSpace:  O(V + E) — PQ may hold duplicates\n\nO((V+E) log V) with a proper binary heap."
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
		"complexity": "Time:   O(V x E) = O(5 x 7) = 35 steps max\nSpace:  O(V)\n\nDetects negative cycles if distances still decrease after V-1 passes."
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
			"'Stamps' is added last despite being close, because its cheapest available " +
			"connection (cost 8 via forms) is expensive. The total MST weight is 11."
		),
		"complexity": "Time:   O(V²) — sorted array PQ\nSpace:  O(V + E) — PQ may hold duplicates\n\nO((V+E) log V) with a proper binary heap."
	},
	{
		"how_it_works": (
			"Finds the shortest path from start to every reachable node by combining " +
			"g(n) — actual cost from start — with h(n) — an admissible heuristic " +
			"estimate to the destination.\n\n" +
			"f(n) = g(n) + h(n). The node with the lowest f is always expanded next. " +
			"Because h never overestimates, the first time a node is closed, its path " +
			"is optimal. Uses abs weights (treats -2 as 2)."
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
		"complexity": "Time:   O(V² ) — sorted array PQ\nSpace:  O(V + E) — open set may hold duplicates\n\nOptimal with admissible heuristic. O((V+E) log V) with binary heap."
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

# ─── Galaxy / Nebula Palette ──────────────────────────────────────────────────
const M_BG:          Color = Color(0.03, 0.02, 0.08)
const M_SURFACE:     Color = Color(0.07, 0.05, 0.13)
const M_SURFACE_V:   Color = Color(0.12, 0.09, 0.22)
const M_PRIMARY:     Color = Color(0.52, 0.32, 1.00)
const M_PRIMARY_C:   Color = Color(0.15, 0.09, 0.36)
const M_SECONDARY:   Color = Color(0.08, 0.88, 0.82)
const M_SECONDARY_C: Color = Color(0.02, 0.20, 0.18)
const M_TERTIARY:    Color = Color(1.00, 0.72, 0.12)
const M_ON_SURF:     Color = Color(0.93, 0.90, 1.00)
const M_ON_SURF_V:   Color = Color(0.57, 0.52, 0.75)
const M_OUTLINE:     Color = Color(0.20, 0.16, 0.38)
const M_OUTLINE_V:   Color = Color(0.38, 0.32, 0.62)
const SHADOW_COL:    Color = Color(0.00, 0.00, 0.08, 0.70)

const RADIUS_CARD: int = 12
const RADIUS_BTN:  int = 8
const RADIUS_CHIP: int = 20

const _ICON_PLAY: Array[String] = [
	"X.........", "XX........", "XXX.......", "XXXX......", "XXXXX.....",
	"XXXXX.....", "XXXX......", "XXX.......", "XX........", "X........."
]
const _ICON_PAUSE: Array[String] = [
	".XX..XX...", ".XX..XX...", ".XX..XX...", ".XX..XX...", ".XX..XX...",
	".XX..XX...", ".XX..XX...", ".XX..XX...", ".XX..XX...", ".XX..XX..."
]

# Node state colors — single source of truth for legend
const C_STATE_DEFAULT:  Color = Color(0.07, 0.05, 0.13)
const C_STATE_FRONTIER: Color = Color(1.00, 0.72, 0.12)
const C_STATE_VISITED:  Color = Color(0.18, 0.16, 0.26)

@onready var memo_label:     Label          = $BottomPanel/MarginContainer/VBoxContainer/MemoLabel
@onready var queue_display:  Label          = $BottomPanel/MarginContainer/VBoxContainer/QueueRow/QueueDisplay
@onready var advance_button: Button         = $BottomPanel/MarginContainer/VBoxContainer/AdvanceButton
@onready var _vbox:          VBoxContainer  = $BottomPanel/MarginContainer/VBoxContainer
@onready var _hsep:          HSeparator     = $BottomPanel/MarginContainer/VBoxContainer/HSeparator
@onready var _queue_title:   Label          = $BottomPanel/MarginContainer/VBoxContainer/QueueRow/QueueTitle
@onready var _bottom_panel:  PanelContainer = $BottomPanel

var _form_header_label:  Label  = null
var _step_count:         int    = 0
var _step_counter_label: Label  = null
var _algo_chip_label:    Label  = null

var _play_icon_tex:  ImageTexture = null
var _pause_icon_tex: ImageTexture = null
var _auto_play:      bool         = false
var _auto_speed:     float        = 1.5
var _auto_timer:     float        = 0.0
var _is_complete:    bool         = false
var _play_btn:       Button       = null


func _ready() -> void:
	advance_button.pressed.connect(_on_advance_pressed)
	queue_display.text = QUEUE_EMPTY_TEXT
	_apply_material_theme()
	memo_label.text = ALGORITHM_NAMES[0] + " selected. Press 'Process Next Memo' to begin."


# ─── Public API ──────────────────────────────────────────────────────────────

func update_message(message: String) -> void:
	memo_label.text = message


func update_queue_display(display_names: Array) -> void:
	if display_names.is_empty():
		queue_display.text = QUEUE_EMPTY_TEXT
		return
	var lines: PackedStringArray = []
	for i: int in display_names.size():
		lines.append("  %d. %s" % [i + 1, display_names[i]])
	queue_display.text = "\n".join(lines)


func disable_advance_button() -> void:
	_auto_play   = false
	_is_complete = true
	_auto_timer  = 0.0
	if _play_btn:
		_play_btn.text = "Play"
		_play_btn.icon = _play_icon_tex
	advance_button.disabled = true
	advance_button.text = "Algorithm Complete"


func enable_advance_button() -> void:
	_auto_play   = false
	_is_complete = false
	_auto_timer  = 0.0
	if _play_btn:
		_play_btn.text = "Play"
		_play_btn.icon = _play_icon_tex
	advance_button.disabled = false
	advance_button.text = "Process Next Memo"
	_step_count = 0
	if _step_counter_label:
		_step_counter_label.text = "STEP 0"


func update_form_header(algorithm_code: String) -> void:
	if _form_header_label:
		_form_header_label.text = "FORM  %s" % algorithm_code


func update_structure_label(label_text: String) -> void:
	_queue_title.text = label_text


func update_welcome(message: String) -> void:
	memo_label.text = message
	queue_display.text = QUEUE_EMPTY_TEXT


# Kept as no-op — algorithm info is now shown on the intro screen.
func update_info_panel(_type_index: int) -> void:
	if _algo_chip_label and _type_index < ALGORITHM_FORM_CODES.size():
		_algo_chip_label.text = ALGORITHM_FORM_CODES[_type_index]


# ─── Signal handlers ─────────────────────────────────────────────────────────

func _do_advance_step() -> void:
	_step_count += 1
	if _step_counter_label:
		_step_counter_label.text = "STEP %d" % _step_count
	advance_requested.emit()


func _on_advance_pressed() -> void:
	_do_advance_step()


func _process(delta: float) -> void:
	if not _auto_play or _is_complete:
		return
	_auto_timer += delta
	if _auto_timer >= _auto_speed:
		_auto_timer = 0.0
		_do_advance_step()


func _on_reset_pressed() -> void:
	reset_requested.emit()


func _on_play_pause_pressed() -> void:
	if _is_complete:
		return
	_auto_play  = not _auto_play
	_auto_timer = 0.0
	if _play_btn:
		_play_btn.text = "Pause" if _auto_play else "Play"
		_play_btn.icon = _pause_icon_tex if _auto_play else _play_icon_tex


# ─── Style helpers ────────────────────────────────────────────────────────────

func _btn_style(bg: Color, border: Color, bw: int, radius: int,
		ml: int = 12, mr: int = 12, mt: int = 6, mb: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left   = ml
	s.content_margin_right  = mr
	s.content_margin_top    = mt
	s.content_margin_bottom = mb
	return s


func _style_button(btn: Button, normal: StyleBoxFlat, hover: StyleBoxFlat,
		pressed: StyleBoxFlat, fc: Color, fhc: Color, fpc: Color) -> void:
	var focus := _btn_style(hover.bg_color, M_SECONDARY, 2, RADIUS_BTN,
			int(normal.content_margin_left), int(normal.content_margin_right),
			int(normal.content_margin_top), int(normal.content_margin_bottom))
	var disabled := _btn_style(Color(M_OUTLINE, 0.30), Color.TRANSPARENT, 0, RADIUS_BTN,
			int(normal.content_margin_left), int(normal.content_margin_right),
			int(normal.content_margin_top), int(normal.content_margin_bottom))
	btn.add_theme_stylebox_override("normal",   normal)
	btn.add_theme_stylebox_override("hover",    hover)
	btn.add_theme_stylebox_override("pressed",  pressed)
	btn.add_theme_stylebox_override("focus",    focus)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color",          fc)
	btn.add_theme_color_override("font_hover_color",    fhc)
	btn.add_theme_color_override("font_pressed_color",  fpc)
	btn.add_theme_color_override("font_focus_color",    fhc)
	btn.add_theme_color_override("font_disabled_color", M_ON_SURF_V)


# ─── Theme construction ───────────────────────────────────────────────────────

func _apply_material_theme() -> void:
	_play_icon_tex  = _make_icon_texture(10, _ICON_PLAY,  M_ON_SURF)
	_pause_icon_tex = _make_icon_texture(10, _ICON_PAUSE, M_ON_SURF)

	# ── BottomPanel background — full-width, top border only ──
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(M_SURFACE.r, M_SURFACE.g, M_SURFACE.b, 0.97)
	panel_style.set_border_width_all(0)
	panel_style.set_border_width(SIDE_TOP, 2)
	panel_style.border_color  = M_PRIMARY
	panel_style.set_corner_radius_all(0)
	panel_style.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.18)
	panel_style.shadow_size   = 20
	panel_style.shadow_offset = Vector2(0.0, -8.0)
	_bottom_panel.add_theme_stylebox_override("panel", panel_style)

	# ── [0] HeaderRow: AlgoChip | spacer | Reset(tiny) | StepChip ──
	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", 6)

	var algo_chip := PanelContainer.new()
	var acs := StyleBoxFlat.new()
	acs.bg_color = M_PRIMARY_C;  acs.border_color = M_PRIMARY
	acs.set_border_width_all(1); acs.set_corner_radius_all(RADIUS_CHIP)
	acs.content_margin_left = 10;  acs.content_margin_right = 10
	acs.content_margin_top  = 3;   acs.content_margin_bottom = 3
	algo_chip.add_theme_stylebox_override("panel", acs)
	_algo_chip_label = Label.new()
	_algo_chip_label.text = "BFS-9A"
	_algo_chip_label.add_theme_color_override("font_color", M_PRIMARY)
	_algo_chip_label.add_theme_font_size_override("font_size", 11)
	algo_chip.add_child(_algo_chip_label)
	_form_header_label = _algo_chip_label
	header_row.add_child(algo_chip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)

	# Tiny Reset button in the header
	var reset_btn := Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.text = "Reset"
	_style_button(reset_btn,
		_btn_style(Color(0,0,0,0),    Color(M_OUTLINE_V,0.5), 1, RADIUS_CHIP, 8, 8, 2, 2),
		_btn_style(M_SECONDARY_C,     M_SECONDARY,            1, RADIUS_CHIP, 8, 8, 2, 2),
		_btn_style(Color(M_SECONDARY_C,0.6), M_SECONDARY,     2, RADIUS_CHIP, 8, 8, 2, 2),
		M_ON_SURF_V, M_ON_SURF, M_ON_SURF)
	reset_btn.add_theme_font_size_override("font_size", 10)
	reset_btn.pressed.connect(_on_reset_pressed)
	header_row.add_child(reset_btn)

	var step_chip := PanelContainer.new()
	var scs := StyleBoxFlat.new()
	scs.bg_color = M_SECONDARY_C;  scs.border_color = M_SECONDARY
	scs.set_border_width_all(1);    scs.set_corner_radius_all(RADIUS_CHIP)
	scs.content_margin_left = 10;   scs.content_margin_right = 10
	scs.content_margin_top  = 3;    scs.content_margin_bottom = 3
	step_chip.add_theme_stylebox_override("panel", scs)
	_step_counter_label = Label.new()
	_step_counter_label.text = "STEP 0"
	_step_counter_label.add_theme_color_override("font_color", M_SECONDARY)
	_step_counter_label.add_theme_font_size_override("font_size", 11)
	step_chip.add_child(_step_counter_label)
	header_row.add_child(step_chip)

	_vbox.add_child(header_row)
	_vbox.add_child(_make_sep(M_OUTLINE, 2))
	_vbox.move_child(header_row, 0)
	_vbox.move_child(_vbox.get_child(_vbox.get_child_count() - 1), 1)

	# ── [2] ControlRow — Play button only ──
	var control_row := HBoxContainer.new()
	control_row.name = "ControlRow"
	control_row.add_theme_constant_override("separation", 6)

	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "Play"
	play_btn.icon = _play_icon_tex
	play_btn.icon_max_width = 10
	_style_button(play_btn,
		_btn_style(M_PRIMARY_C, M_PRIMARY, 1, RADIUS_BTN),
		_btn_style(M_PRIMARY_C, M_PRIMARY, 2, RADIUS_BTN),
		_btn_style(M_PRIMARY,   M_PRIMARY, 2, RADIUS_BTN),
		M_ON_SURF, M_ON_SURF, M_ON_SURF)
	play_btn.add_theme_font_size_override("font_size", 12)
	play_btn.pressed.connect(_on_play_pause_pressed)
	control_row.add_child(play_btn)
	_play_btn = play_btn

	_vbox.add_child(control_row)
	_vbox.add_child(_make_sep(M_OUTLINE, 3))
	_vbox.move_child(control_row, 2)
	_vbox.move_child(_vbox.get_child(_vbox.get_child_count() - 1), 3)

	# ── [4] MemoLabel ──
	memo_label.add_theme_color_override("font_color", M_ON_SURF)
	memo_label.add_theme_font_size_override("font_size", 12)

	# ── [5] HSep ──
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = M_OUTLINE
	sep_style.set_content_margin_all(1.0)
	_hsep.add_theme_stylebox_override("separator", sep_style)
	_hsep.add_theme_constant_override("separation", 5)

	# ── [6] QueueRow ──
	_queue_title.text = ">> THE QUEUE:"
	_queue_title.add_theme_color_override("font_color", M_SECONDARY)
	_queue_title.add_theme_font_size_override("font_size", 11)
	queue_display.add_theme_color_override("font_color", M_ON_SURF_V)
	queue_display.add_theme_font_size_override("font_size", 11)

	# ── [7] AdvanceButton (primary CTA) ──
	advance_button.text = "Process Next Memo"

	var adv_n := _btn_style(M_PRIMARY, Color.TRANSPARENT, 0, RADIUS_BTN, 16, 16, 10, 10)
	adv_n.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.50)
	adv_n.shadow_size   = 10
	adv_n.shadow_offset = Vector2(0, 3)

	var adv_h := _btn_style(Color(0.62, 0.42, 1.00), Color.TRANSPARENT, 0, RADIUS_BTN, 16, 16, 10, 10)
	adv_h.shadow_color  = Color(M_PRIMARY.r, M_PRIMARY.g, M_PRIMARY.b, 0.50)
	adv_h.shadow_size   = 14
	adv_h.shadow_offset = Vector2(0, 3)

	var adv_p := _btn_style(Color(0.38, 0.22, 0.85), Color.TRANSPARENT, 0, RADIUS_BTN, 16, 16, 10, 10)
	adv_p.shadow_size = 3

	var adv_f := _btn_style(Color(0.62, 0.42, 1.00), M_SECONDARY, 2, RADIUS_BTN, 16, 16, 10, 10)
	var adv_d := _btn_style(Color(M_OUTLINE, 0.40), Color.TRANSPARENT, 0, RADIUS_BTN, 16, 16, 10, 10)

	advance_button.add_theme_stylebox_override("normal",   adv_n)
	advance_button.add_theme_stylebox_override("hover",    adv_h)
	advance_button.add_theme_stylebox_override("pressed",  adv_p)
	advance_button.add_theme_stylebox_override("focus",    adv_f)
	advance_button.add_theme_stylebox_override("disabled", adv_d)
	advance_button.add_theme_font_size_override("font_size", 14)
	advance_button.add_theme_color_override("font_color",          Color.WHITE)
	advance_button.add_theme_color_override("font_hover_color",    Color.WHITE)
	advance_button.add_theme_color_override("font_pressed_color",  Color.WHITE)
	advance_button.add_theme_color_override("font_focus_color",    Color.WHITE)
	advance_button.add_theme_color_override("font_disabled_color", M_ON_SURF_V)


# ─── Helpers ─────────────────────────────────────────────────────────────────

func _make_sep(color: Color, thickness: int) -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(1.0)
	sep.add_theme_stylebox_override("separator", style)
	sep.add_theme_constant_override("separation", thickness)
	return sep


static func _make_icon_texture(sz: int, bitmask: Array[String], color: Color) -> ImageTexture:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for row: int in bitmask.size():
		for col: int in bitmask[row].length():
			if col < sz and row < sz and bitmask[row][col] == "X":
				img.set_pixel(col, row, color)
	return ImageTexture.create_from_image(img)
