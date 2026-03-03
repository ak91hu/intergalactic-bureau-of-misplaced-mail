# Project Documentation
## The Intergalactic Bureau of Misplaced Mail

A Godot 4 educational game that visualizes **nine classic graph algorithms** through a
bureaucratic comedy lens. Players step through each algorithm one action at a time,
watching the graph light up as nodes are discovered, queued, and finalized. Frontier
nodes pulse with an animated amber glow; examined edges flash cyan; a twinkling
starfield renders behind the graph.

Built without any external libraries — pure GDScript, programmatic UI, and `_draw()` rendering.

---

## Table of Contents

1. [Running the Project](#running-the-project)
2. [Repository Layout](#repository-layout)
3. [Scene Trees](#scene-trees)
4. [Architecture Overview](#architecture-overview)
5. [Graph Data](#graph-data)
6. [Algorithm Strategy Pattern](#algorithm-strategy-pattern)
7. [StepResult Contract](#stepresult-contract)
8. [Signal Flow](#signal-flow)
9. [Script Reference](#script-reference)
10. [Adding a New Algorithm](#adding-a-new-algorithm)
11. [Visual States](#visual-states)
12. [UI Injection Pattern](#ui-injection-pattern)
13. [Known Design Decisions](#known-design-decisions)
14. [GDScript Pitfalls](#gdscript-pitfalls)

---

## Running the Project

### In the Godot Editor

Open the project in **Godot 4.6** (tested on 4.6.1 stable).

- Press **F5** to run. `MenuScene.tscn` is the main scene.
- No external dependencies, plugins, or exports required.

### In the Browser (pre-exported)

```bash
cd export/web
python server.py
```

Then open **http://localhost:8080** in Chrome or Firefox. Use `server.py` — not
`python -m http.server`. The custom server sets the required `Cross-Origin-Opener-Policy`
and `Cross-Origin-Embedder-Policy` headers that Godot 4's WebAssembly runtime needs.

### Re-exporting after changes

```bash
"C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe" \
  --headless --export-release "Web" "export/web/index.html" \
  --path "C:/testingClaude/myFirstGame"
```

Then press `Ctrl+Shift+R` in the browser to hard-refresh.

---

## Repository Layout

```
myFirstGame/
│
├── Main.tscn                        # Game scene (build in editor)
├── DepartmentNode.tscn              # Department node prefab (build in editor)
├── MenuScene.tscn                   # Main menu scene (fully generated, no editor nodes)
│
├── Main.gd                          # Orchestrator — builds visuals, wires signals, starfield
├── GraphManager.gd                  # Pure logic/data node — owns graph + active algorithm
├── GameUI.gd                        # Bottom panel UI — memo, structure display, info popup
├── DepartmentNode.gd                # Per-node visual (renders via _draw, animated glow)
├── MenuScene.gd                     # Main menu — 9 clickable algorithm cards (3x3)
├── GameState.gd                     # Autoload singleton — carries selected_algorithm between scenes
│
├── AlgorithmBase.gd                 # Base class — defines interface all algorithms must implement
├── AlgorithmBFS.gd                  # Breadth-First Search
├── AlgorithmDFS.gd                  # Depth-First Search
├── AlgorithmTopoSort.gd             # Topological Sort (Kahn's algorithm)
├── AlgorithmDijkstra.gd             # Dijkstra's Shortest Path (abs weights)
├── AlgorithmBellmanFord.gd          # Bellman-Ford (handles negative weights)
├── AlgorithmPrim.gd                 # Prim's Minimum Spanning Tree
├── AlgorithmAStar.gd                # A* Heuristic Search
├── AlgorithmFloydWarshall.gd        # Floyd-Warshall All-Pairs Shortest Paths
├── AlgorithmKruskal.gd              # Kruskal's Minimum Spanning Tree (Union-Find)
│
├── export/web/
│   ├── index.html                   # Game launcher shell
│   ├── index.pck                    # Compiled game scripts + scenes
│   ├── index.wasm                   # Godot engine WebAssembly (~36 MB, gitignored)
│   ├── index.js                     # Godot JavaScript glue (~309 KB, gitignored)
│   └── server.py                    # Dev server (sets required COOP/COEP headers)
│
├── CLAUDE.md                        # AI agent instructions
├── PROJECT.md                       # This file — developer documentation
├── GAME_GUIDE.md                    # Player-facing documentation
└── README.md                        # GitHub overview
```

---

## Scene Trees

### `DepartmentNode.tscn`

```
Node2D  [script: DepartmentNode.gd]   <- rename root to "DepartmentNode"
```

A single root node. All rendering is done via `_draw()` — no child nodes needed.

### `Main.tscn`

```
Node2D  [script: Main.gd]                         <- rename to "Main"
|-- Node              "GraphManager"               [script: GraphManager.gd]
|-- Node2D            "GraphLayer"                 (panned by Main._unhandled_input)
|   |-- Node2D        "EdgesContainer"
|   `-- Node2D        "NodesContainer"
`-- CanvasLayer
    `-- Control       "GameUI"                     [script: GameUI.gd]  (Full Rect)
        `-- PanelContainer  "BottomPanel"          (Bottom Wide, min-height 210, offset_top -210)
            `-- MarginContainer                    (margins 12/12/8/8)
                `-- VBoxContainer
                    |-- Label       "MemoLabel"    (Autowrap: Word, min height: 48)
                    |-- HSeparator
                    |-- HBoxContainer "QueueRow"
                    |   |-- Label   "QueueTitle"   (text "THE QUEUE:")
                    |   `-- Label   "QueueDisplay" (Autowrap: Word, H size: Expand)
                    `-- Button      "AdvanceButton" (text "Process Next Memo")
```

**GameUI sizing:** Anchors preset = Full Rect.
**BottomPanel sizing:** Anchors preset = Bottom Wide, `offset_top = -210`.

The `HeaderRow` (AlgoChip + StepChip), `ControlRow` (Reset + Info buttons), and all
theming are injected **programmatically** in `GameUI._apply_material_theme()`.

### `MenuScene.tscn`

Fully generated in `MenuScene._ready()`. No editor nodes. Contains a 3×3 GridContainer
of algorithm cards, each clickable and branded with category color and difficulty stars.

---

## Architecture Overview

```
+-------------------------------------------------+
|  MenuScene.gd                                   |
|  - 9 algorithm cards (3x3 grid)                 |
|  - On card click: sets GameState.selected_algo   |
|    then changes scene to Main.tscn               |
+------------------------+-----------------------+

+------------------------+-----------------------+
|  Main.gd  (orchestrator)                        |
|                                                 |
|  _ready()           reads GameState.selected_   |
|  _build_node_visuals()  -> DepartmentNode       |
|  _build_edge_visuals()  -> Line2D + _edge_map   |
|  _wire_signals()        -> all signal wiring    |
|  _process(delta)        -> starfield animation  |
|  _draw()                -> starfield + nebulae  |
+-------------------+------------------+----------+
                    |                  |
                    v                  v
+--------------------+    +---------------------------+
|  GraphManager.gd   |    |  GameUI.gd                |
|                    |    |                           |
|  DEPARTMENTS dict  |    |  Reset button             |
|  active algorithm  |    |  Info popup toggle        |
|  AlgorithmType enum|    |  MemoLabel                |
|                    |    |  QueueDisplay label       |
|  signals emitted:  |    |  AdvanceButton            |
|  node_state_changed|    |  AlgoChip + StepChip      |
|  queue_updated     |    |                           |
|  step_message_chgd |    |  signals emitted:         |
|  algorithm_complete|    |  advance_requested        |
|  edge_examined     |    |  reset_requested          |
+--------------------+    +---------------------------+
         |
         v
+-------------------------------------------+
|  AlgorithmBase  (RefCounted)              |
|  +-- AlgorithmBFS                         |
|  +-- AlgorithmDFS                         |
|  +-- AlgorithmTopoSort                    |
|  +-- AlgorithmDijkstra                    |
|  +-- AlgorithmBellmanFord                 |
|  +-- AlgorithmPrim                        |
|  +-- AlgorithmAStar                       |
|  +-- AlgorithmFloydWarshall               |
|  `-- AlgorithmKruskal                     |
+-------------------------------------------+
```

**Key architectural rules:**

- `GraphManager` never references scene nodes. It only emits signals.
- Algorithm scripts (`AlgorithmBase` subclasses) extend `RefCounted` — they are pure
  data objects, never added to the scene tree.
- `Main.gd` owns all cross-node wiring. No script other than Main calls methods on
  other top-level nodes.
- `MenuScene` communicates with `Main` exclusively via `GameState` (the autoload
  singleton) — no direct scene reference.

---

## Graph Data

Defined as `DEPARTMENTS` in `GraphManager.gd`. The graph is **directed** with integer
edge weights. Node IDs are short lowercase strings.

```
                    redundancy (start)
                   /          \
              [3] /            \ [1]
                 /              \
             forms            delays
            /     \               \
        [8] /       \ [-2]     [6] \
           /         \             \
        stamps       lost ----------+
           \          /
        [1] \    [4] /
             \      /
           destination (end)
```

| ID | Department Name | Neighbors | Weights |
|---|---|---|---|
| `redundancy` | Dept. of Redundancy Dept. | forms, delays | forms:3, delays:1 |
| `forms` | Bureau of Unnecessary Forms | stamps, lost | stamps:8, lost:**-2** |
| `delays` | Office of Perpetual Delays | lost | lost:6 |
| `stamps` | Division of Rubber Stamps | destination | destination:1 |
| `lost` | Archives of Misplaced Items | destination | destination:4 |
| `destination` | Actual Mail Delivery\* | *(none)* | *(none)* |

**Weight design rationale:**

The `-2` weight on `forms -> lost` creates several interesting contrasts:

| Algorithm | Path Found | Total Cost | Why |
|---|---|---|---|
| Dijkstra | redundancy->forms->lost->destination | **9** | Uses `abs(-2)=2`, so 3+2+4=9 |
| Bellman-Ford | redundancy->forms->lost->destination | **5** | Uses raw -2, so 3+(−2)+4=5 |
| Floyd-Warshall | all pairs including same path | **5** | Uses raw -2, same result as BF |
| A* | redundancy->forms->lost->destination | **9** | Uses abs weights (same as Dijkstra) |
| Prim's / Kruskal | all 6 nodes connected | **11** total | Undirected, abs weights, MST |

---

## Algorithm Strategy Pattern

`GraphManager` holds an `_active_algorithm: AlgorithmBase` and delegates all
algorithmic logic to it. Switching algorithms creates a fresh instance; no state leaks.

```gdscript
# GraphManager.gd
const ALGORITHM_SCRIPTS: Array = [
    preload("res://AlgorithmBFS.gd"),           # 0
    preload("res://AlgorithmDFS.gd"),           # 1
    preload("res://AlgorithmTopoSort.gd"),      # 2
    preload("res://AlgorithmDijkstra.gd"),      # 3
    preload("res://AlgorithmBellmanFord.gd"),   # 4
    preload("res://AlgorithmPrim.gd"),          # 5
    preload("res://AlgorithmAStar.gd"),         # 6
    preload("res://AlgorithmFloydWarshall.gd"), # 7
    preload("res://AlgorithmKruskal.gd"),       # 8
]

func set_algorithm(type: int) -> void:
    _current_type = type
    _active_algorithm = ALGORITHM_SCRIPTS[type].new()
```

The array index aligns with the `AlgorithmType` enum:

```gdscript
enum AlgorithmType {
    BFS, DFS, TOPO_SORT, DIJKSTRA, BELLMAN_FORD, PRIM, A_STAR, FLOYD_WARSHALL, KRUSKAL
    # 0    1      2         3          4           5      6          7             8
}
```

### Advance lifecycle

On each button press, `GraphManager.advance_algorithm()` runs:

```
First press:   _active_algorithm._initialized == false
               -> calls initialize(DEPARTMENTS, START_NODE)
               -> returns StepResult, sets _initialized = true

Subsequent:    _active_algorithm.is_complete() == false
               -> calls advance(DEPARTMENTS)
               -> returns StepResult

After done:    is_complete() == true -> early return, no signal emitted
```

---

## StepResult Contract

Every `initialize()` and `advance()` call returns a `Dictionary` with four required
keys and one optional key:

```gdscript
{
    "state_changes": [           # Array of Dicts — visual updates to apply
        {"id": "forms", "state": "frontier"},
        {"id": "lost",  "state": "visited"},
    ],
    "structure": [               # Array of Strings — structure panel contents
        "Bureau of Unnecessary Forms",
        "[3] — Office of Perpetual Delays",
    ],
    "message":    "...",         # String — the bureaucratic memo shown in MemoLabel
    "is_complete": false,        # bool — triggers algorithm_complete signal if true

    # Optional — triggers edge flash animation in Main._on_edge_examined()
    "examined_edge": {"from": "redundancy", "to": "forms"}
}
```

`GraphManager._process_step_result()` translates this dict into signal emissions:

```gdscript
func _process_step_result(result: Dictionary) -> void:
    for change in result["state_changes"]:
        node_state_changed.emit(change["id"], change["state"])
    queue_updated.emit(result["structure"])
    step_message_changed.emit(result["message"])
    if result["has"]("examined_edge"):
        var ee: Dictionary = result.get("examined_edge", {})
        edge_examined.emit(ee.get("from", ""), ee.get("to", ""))
    if result["is_complete"]:
        algorithm_complete.emit()
```

**Algorithms that emit `examined_edge`:** BFS, DFS, TopoSort, Dijkstra, Bellman-Ford,
Prim, A*, Kruskal (all except Floyd-Warshall, which operates on a global matrix
without per-edge step granularity).

---

## Signal Flow

```
User selects algorithm card in MenuScene
        |
        v
MenuScene -> GameState.selected_algorithm = card_index
          -> get_tree().change_scene_to_file("res://Main.tscn")

In Main._ready():
        -> graph_manager.set_algorithm(GameState.selected_algorithm)
        -> game_ui.update_info_panel(GameState.selected_algorithm)
        -> game_ui.update_form_header(...)
        -> game_ui.update_welcome(...)

-------------------------------------------------------------------

User presses "Process Next Memo"
        |
        v
GameUI  -> advance_requested.emit()
        |
        v
GraphManager.advance_algorithm()
        |
        |-- node_state_changed(id, state)   -> Main._on_node_state_changed()
        |                                         -> DepartmentNode.set_visual_state()
        |
        |-- queue_updated(names_array)      -> GameUI.update_queue_display()
        |
        |-- step_message_changed(text)      -> GameUI.update_message()
        |
        |-- edge_examined(from_id, to_id)   -> Main._on_edge_examined()
        |                                         -> tween edge color cyan->normal
        |
        `-- algorithm_complete              -> GameUI.disable_advance_button()

-------------------------------------------------------------------

User presses "Reset"
        |
        v
GameUI  -> reset_requested.emit()
        |
        v
Main._on_reset_requested()
        |-- graph_manager.reset_algorithm()   # re-instantiates same algorithm type
        |-- _reset_all_node_visuals()
        |-- game_ui.enable_advance_button()
        |-- game_ui.update_queue_display([])
        `-- game_ui.update_welcome(graph_manager.get_active_algorithm_welcome())
```

---

## Script Reference

### `GameState.gd`
Autoload singleton (registered in `project.godot`). Carries the selected algorithm index
between the menu scene and the game scene.

```gdscript
var selected_algorithm: int = 0
```

---

### `AlgorithmBase.gd`
Extends `RefCounted`. Declares `var _initialized: bool = false`.
All methods return empty values — subclasses override everything.

| Method | Signature | Purpose |
|---|---|---|
| `initialize` | `(graph_data, start_node) -> Dict` | First-call setup; must set `_initialized = true` |
| `advance` | `(graph_data) -> Dict` | One step of the algorithm; returns StepResult |
| `is_complete` | `() -> bool` | True when algorithm has finished |
| `get_name` | `() -> String` | Human-readable algorithm name |
| `get_structure_label` | `() -> String` | Label above the structure display |
| `get_welcome_message` | `() -> String` | Intro text shown before the first step |

---

### `AlgorithmBFS.gd`
Step granularity: **init -> dequeue -> examine each neighbor (1 per step) -> exhausted -> repeat**

Emits `examined_edge` on every neighbor examination (both visited and newly-discovered).

| State var | Type | Purpose |
|---|---|---|
| `_visited` | Dictionary | Set of visited node IDs |
| `_frontier` | `Array[String]` | FIFO queue |
| `_active_node` | String | Node currently being expanded |
| `_active_neighbor_index` | int | Index into current node's neighbor list |

---

### `AlgorithmDFS.gd`
Same step granularity as BFS. Nodes are marked **visited when popped**, not when pushed,
producing standard DFS behavior with possible stale stack entries.

Emits `examined_edge` on every neighbor examination.

| State var | Type | Purpose |
|---|---|---|
| `_visited` | Dictionary | Set of visited node IDs |
| `_stack` | `Array[String]` | LIFO stack (`push_back` / `pop_back`) |
| `_active_node` | String | Node currently being expanded |
| `_active_neighbor_index` | int | Index into current node's neighbor list |

Structure display shows the stack from **top to bottom** (last-in first shown).

---

### `AlgorithmTopoSort.gd`  *(Kahn's Algorithm)*
Does **not** use a start node — ignores the `start_node` parameter and processes all
zero-in-degree nodes. `initialize()` computes all in-degrees and seeds the queue.

Emits `examined_edge` when decrementing a neighbor's in-degree.

| State var | Type | Purpose |
|---|---|---|
| `_in_degree` | Dictionary | Remaining in-degree count per node |
| `_queue` | `Array[String]` | FIFO queue of zero-in-degree nodes |
| `_topo_order` | `Array[String]` | Nodes in the order they were dequeued |
| `_active_node` | String | Node being expanded (neighbor decrement phase) |
| `_active_neighbor_index` | int | Index into current node's neighbor list |

---

### `AlgorithmDijkstra.gd`
Uses `abs(weight)` on all edges — the `-2` edge is treated as `2`. Implements **lazy
deletion**: stale PQ entries produce an explanatory "stale memo" message.

Priority queue: `Array` of `[float_cost, String_id]` pairs, re-sorted with `.sort()`.
O(n²) total — fine for n=6.

Emits `examined_edge` on all three branches of `_relax_next_neighbor()`.

| State var | Type | Purpose |
|---|---|---|
| `_dist` | Dictionary | Best known distance per node |
| `_prev` | Dictionary | Previous node on the best path |
| `_visited` | Dictionary | Finalized nodes |
| `_pq` | Array | Sorted priority queue of `[cost, id]` pairs |
| `_active_node` | String | Node currently being relaxed |
| `_active_cost` | float | Cost at which `_active_node` was extracted |

---

### `AlgorithmBellmanFord.gd`
Uses **raw weights including negative values**. Builds a flat edge list at init and
iterates over it `|V|−1 = 5` times. One edge relaxation per `advance()` call.
Early termination fires if a full pass produces zero relaxations.

Emits `examined_edge` on every edge relaxation step.

| State var | Type | Purpose |
|---|---|---|
| `_dist` | Dictionary | Best known distance (int, sentinel: `1 << 29`) |
| `_prev` | Dictionary | Previous node on the best path |
| `_edges` | Array | Flat list of `[from_id, to_id, weight]` (7 directed edges) |
| `_current_pass` | int | Which pass (0-indexed) we are in |
| `_current_edge_index` | int | Which edge within the current pass |
| `_relaxed_in_pass` | bool | Whether any relaxation occurred in the current pass |

---

### `AlgorithmPrim.gd`
Builds an **undirected** adjacency (`_undirected`) in `initialize()` using `abs(weight)`.
Implements lazy deletion (same pattern as Dijkstra). The `_key` dict tracks the
minimum connection cost to the growing MST for each unvisited node.

Emits `examined_edge` on all three branches of `_update_next_neighbor()`.

| State var | Type | Purpose |
|---|---|---|
| `_in_mst` | Dictionary | Set of nodes already added to MST |
| `_key` | Dictionary | Minimum cost to connect each node to MST |
| `_parent` | Dictionary | Which MST node connects to this node |
| `_pq` | Array | Sorted priority queue of `[cost, id]` pairs |
| `_mst_edges` | Array | Accumulated list of `[from, to, cost]` MST edges |
| `_undirected` | Dictionary | `node_id -> {neighbor_id: weight}` adjacency |

---

### `AlgorithmAStar.gd`
Uses `abs(weight)` on all edges (same as Dijkstra). Adds an admissible heuristic
`h(n)` that estimates cost-to-destination. Sorts the OPEN set by `f(n) = g(n) + h(n)`.

**Heuristic values** (hand-crafted, admissible under abs weights):

```
h = { redundancy:5, forms:6, delays:10, stamps:1, lost:4, destination:0 }
```

The high `h=10` for `delays` keeps it out of the OPEN set early — A* skips that
branch entirely, demonstrating heuristic guidance.

Emits `examined_edge` on every neighbor examination.

| State var | Type | Purpose |
|---|---|---|
| `_open` | Array | OPEN set — `[f, g, node_id]` triplets, sorted by f |
| `_closed` | Dictionary | Set of fully explored nodes |
| `_g` | Dictionary | Actual cost from start to each node |
| `_prev` | Dictionary | Previous node on the best path |
| `_h` | Dictionary | Static heuristic values per node |

Structure display: `"[f=N g=M] — DeptName"` for non-CLOSED entries.

**Key story:** A* finds cost-9 path (same as Dijkstra, both use abs weights) but
expands fewer nodes — it never enters the `delays` branch until forced.

---

### `AlgorithmFloydWarshall.gd`
Computes **all-pairs shortest paths** in a single sweep over all intermediate nodes.
Uses **real weights including -2**. No per-node state changes (algorithm is global).

Step granularity: **one k-iteration per `advance()` call** — 6 total steps.

**Does NOT emit `examined_edge`** — no per-edge step granularity.
**Does NOT emit state_changes** — no individual node traversal.

| State var | Type | Purpose |
|---|---|---|
| `_dist` | Array | 2D matrix: `_dist[i][j]` = shortest distance from node i to j |
| `_next` | Array | 2D matrix: `_next[i][j]` = first hop on shortest path i->j |
| `_node_list` | Array | Ordered list of node IDs (insertion order from DEPARTMENTS) |
| `_k` | int | Current intermediate node index (0-5) |

Structure display: current `dist[node][destination]` for all nodes.

**Key educational moment:** After k=1 (via forms), dist[redundancy][lost] drops
from INF to 1 (3 + -2 = 1). After k=4 (via lost), dist[redundancy][destination]
becomes 5 (1 + 4). Final answer: 5, vs Dijkstra's 9 with abs weights.

---

### `AlgorithmKruskal.gd`
Builds the MST by sorting **all undirected edges** by weight and greedily accepting
those that do not create a cycle. Uses **Union-Find with path compression and union
by rank** for cycle detection.

Uses `abs(weight)` on all edges. Emits `examined_edge` for both accepted and rejected edges.

**Sorted undirected edges (abs weights):**
```
cost 1: redundancy <-> delays
cost 1: stamps <-> destination
cost 2: forms <-> lost
cost 3: redundancy <-> forms
cost 4: lost <-> destination
cost 6: delays <-> lost
cost 8: forms <-> stamps
```

In this graph, all 5 MST edges are accepted in sequence without any rejections.

| State var | Type | Purpose |
|---|---|---|
| `_parent` | Dictionary | Union-Find parent pointers |
| `_rank` | Dictionary | Union-Find rank for union-by-rank |
| `_sorted_edges` | Array | All undirected edges sorted by abs weight |
| `_edge_index` | int | Current position in sorted edge list |
| `_mst_edges` | Array | Accepted MST edges |
| `_pending_visited` | Array | Nodes accepted in previous step, waiting to go "visited" |

**`_pending_visited` pattern:** When an edge is accepted, both endpoints go to
`"frontier"` state. On the *next* `advance()` call, the pending nodes are marked
`"visited"` before the next edge is examined. This creates a visible two-step
frontier->visited transition.

**Contrast with Prim's:** Same MST weight (11), opposite discovery strategy.
Kruskal sorts all edges globally and picks the cheapest non-cycle edge.
Prim's grows outward from one node, always taking the cheapest edge adjacent to the current MST.

---

### `GraphManager.gd`
Pure data/logic node. Never references scene nodes. All output is via signals.

**Signals:**

| Signal | When emitted |
|---|---|
| `node_state_changed(id, state)` | After each state_change entry in a StepResult |
| `queue_updated(items)` | After every advance() call (carries structure Array) |
| `step_message_changed(msg)` | After every advance() call (carries message String) |
| `algorithm_complete` | When a StepResult has `is_complete: true` |
| `edge_examined(from_id, to_id)` | When a StepResult includes `examined_edge` key |

**Methods:**

| Method | Purpose |
|---|---|
| `set_algorithm(type: int)` | Instantiates a fresh algorithm of the given type |
| `reset_algorithm()` | Calls `set_algorithm(_current_type)` — resets same algorithm |
| `advance_algorithm()` | Routes to `initialize()` or `advance()` based on `_initialized` |
| `get_department_name(id)` | Returns the display name for a node ID |
| `get_all_department_ids()` | Returns all node IDs (for scene construction) |
| `get_neighbors_of(id)` | Returns directed neighbor list |
| `get_edge_weight(from, to)` | Returns raw integer weight (including negative) |
| `get_active_algorithm_welcome()` | Returns the welcome message for the current algorithm |

---

### `GameUI.gd`
Extends `Control`. All child nodes are `@onready` references to scene-tree nodes.
Extra UI (HeaderRow, ControlRow, Info popup) is injected programmatically in
`_apply_material_theme()`.

**Parallel constant arrays** (all length 9, indexed by AlgorithmType):

```gdscript
const ALGORITHM_FORM_CODES:       Array[String]  # ["BFS-9A", "DFS-2B", ..., "KRU-7F"]
const ALGORITHM_STRUCTURE_LABELS: Array[String]  # [">> THE QUEUE:", ..., ">> EDGE CANDIDATES:"]
const ALGORITHM_NAMES:            Array[String]  # ["BFS — Breadth-First Search", ...]
const ALGORITHM_INFO:             Array          # Array of info dicts (9 entries)
```

**Signals emitted:**

| Signal | When |
|---|---|
| `advance_requested` | Advance button pressed |
| `reset_requested` | Reset button pressed |

**Public methods:**

| Method | Purpose |
|---|---|
| `update_message(text)` | Sets MemoLabel text |
| `update_queue_display(names)` | Updates QueueDisplay with numbered list |
| `update_form_header(code)` | Updates the AlgoChip (e.g. "BFS-9A") |
| `update_structure_label(text)` | Updates the QueueTitle label |
| `update_welcome(message)` | Sets memo text + clears queue display |
| `update_info_panel(type_index)` | Populates the Info popup content |
| `enable_advance_button()` | Re-enables + resets step counter + button text |
| `disable_advance_button()` | Disables button, changes text to "Algorithm Complete" |

---

### `DepartmentNode.gd`
Extends `Node2D`. Renders entirely via `_draw()` — no child nodes needed.
Animated frontier glow implemented via a looping `Tween`.

| Visual state | Fill | Border | Extra |
|---|---|---|---|
| `"default"` | Deep space dark | Dim outline | No glow |
| `"frontier"` | Amber tinted dark | Bright amber | Pulsing amber shadow glow (10-24px, 0.8s cycle) |
| `"visited"` | Charcoal | Muted outline | No glow |

**Animation methods:**

| Member | Type | Purpose |
|---|---|---|
| `_glow_size` | float | Current glow shadow size (10.0..24.0, animated) |
| `_glow_tween` | Tween | Active looping tween (null when not frontier) |
| `_set_glow_size(size)` | method | Setter for tween_method target; calls queue_redraw() |

When `set_visual_state("frontier")` is called, a looping tween is created:
`10.0 -> 24.0 -> 10.0` over 1.6s total (two 0.8s legs with EASE_IN_OUT). When the
state changes away from frontier, the tween is killed and `_glow_size` resets to 16.0.

---

### `Main.gd`
Orchestrator. Builds visuals, wires signals, renders starfield, and handles edge flash.

**New visual members (v2.0):**

| Member | Type | Purpose |
|---|---|---|
| `_edge_map` | Dictionary | `"from_id|to_id"` -> `{"shaft": Line2D, "head": Line2D}` |
| `_stars` | Array | 150 star entries: `[Vector2, radius, base_alpha, speed, phase]` |
| `_bg_time` | float | Accumulated time for star twinkle animation |
| `EDGE_HIGHLIGHT_COLOR` | Color | Cosmic cyan `Color(0.08, 0.88, 0.82, 1.0)` — edge flash color |

**Methods:**

| Method | Purpose |
|---|---|
| `_build_node_visuals()` | Instantiates one DepartmentNode per department |
| `_build_edge_visuals()` | Creates Line2D shafts + arrowheads; stores in `_edge_map` |
| `_draw_directed_edge(from, to, weight)` | Draws one directed edge; returns `{"shaft", "head"}` |
| `_wire_signals()` | Connects all signals including `edge_examined` |
| `_process(delta)` | Advances `_bg_time`, calls `queue_redraw()` for starfield |
| `_draw()` | Renders background, 3 nebula circles, 150 twinkling stars |
| `_on_node_state_changed(id, state)` | Forwards to DepartmentNode.set_visual_state() |
| `_on_edge_examined(from_id, to_id)` | Tweens edge+head color: cyan (0.1s) -> normal (0.55s) |
| `_on_reset_requested()` | Resets algorithm, visuals, and UI |
| `_reset_all_node_visuals()` | Sets all department nodes back to "default" |

**Starfield:** 150 stars generated at `_ready()` using `randomize()`. Each star has a
position, radius, base alpha, twinkle speed, and phase offset. `_draw()` renders the
deep space background, three translucent nebula circles (purple, blue, deep), then
the stars with `sin(_bg_time * speed + phase)` alpha variation.

**Edge flash:** `_on_edge_examined()` looks up the edge in `_edge_map` and tweens
`default_color` on both the shaft and arrowhead `Line2D` nodes:
cyan (0.1s) -> EDGE_COLOR (0.55s).

---

### `MenuScene.gd`
Fully generated main menu. Sets `GameState.selected_algorithm` and changes scene.

**`CARD_DATA` constant** — Array of 9 Dicts, one per algorithm:

```gdscript
{
    "short":      "BFS",                      # short label on card
    "full":       "BFS — Breadth-First Search", # full algorithm name
    "form_code":  "BFS-9A",
    "difficulty": 1,                          # 1-3, shown as * on card
    "category":   "TRAVERSAL",               # category chip label
    "cat_color":  Color(0.30, 0.70, 1.00),   # category chip color
    "insight":    "Explores level by level.", # one-line description
    "index":      0                           # AlgorithmType index
}
```

---

## Adding a New Algorithm

1. **Create `AlgorithmYourAlgo.gd`** extending `AlgorithmBase`:
   ```gdscript
   class_name AlgorithmYourAlgo
   extends AlgorithmBase

   func get_name() -> String: return "Your Algorithm"
   func get_structure_label() -> String: return ">> YOUR STRUCTURE:"
   func get_welcome_message() -> String: return "Welcome text..."
   func is_complete() -> bool: return _is_complete_flag

   func initialize(graph_data: Dictionary, start_node: String) -> Dictionary:
       # ... setup logic ...
       _initialized = true
       return { "state_changes": [...], "structure": [...], "message": "...", "is_complete": false }

   func advance(graph_data: Dictionary) -> Dictionary:
       # ... one step of logic ...
       return { "state_changes": [...], "structure": [...], "message": "...", "is_complete": false }
       # Optionally add: "examined_edge": {"from": from_id, "to": to_id}
   ```

2. **In `GraphManager.gd`**, add to `AlgorithmType` enum and `ALGORITHM_SCRIPTS`:
   ```gdscript
   enum AlgorithmType { ..., YOUR_ALGO }  # append
   const ALGORITHM_SCRIPTS: Array = [
       ...,
       preload("res://AlgorithmYourAlgo.gd"),  # same index as enum
   ]
   ```

3. **In `GameUI.gd`**, append to all four parallel constant arrays:
   ```gdscript
   const ALGORITHM_FORM_CODES:       Array[String] = [..., "FORM-CODE"]
   const ALGORITHM_STRUCTURE_LABELS: Array[String] = [..., ">> YOUR STRUCTURE:"]
   const ALGORITHM_NAMES:            Array[String] = [..., "Your Algo — Short Description"]
   const ALGORITHM_INFO:             Array          = [..., {how_it_works: "...", ...}]
   ```

4. **In `MenuScene.gd`**, append to `CARD_DATA`:
   ```gdscript
   { "short": "SHT", "full": "Your Algorithm", "form_code": "FORM-CODE",
     "difficulty": 2, "category": "CATEGORY", "cat_color": Color(...),
     "insight": "One line.", "index": N }
   ```

5. **If your algorithm examines individual edges**, include
   `"examined_edge": {"from": from_id, "to": to_id}` in the relevant StepResult
   returns. This is handled automatically by `GraphManager._process_step_result()`.

See `PROJECT.md` (this file) for the full StepResult contract.

---

## Visual States

Only three states exist. All algorithms must map their internal states to these three:

| State | When to use |
|---|---|
| `"default"` | Node not yet discovered or after a reset |
| `"frontier"` | Node is in the active data structure (queue, stack, PQ, OPEN set) |
| `"visited"` | Node has been fully processed / finalized / added to MST / CLOSED |

`DepartmentNode.set_visual_state()` ignores redundant calls (same state -> no redraw).
When set to `"frontier"`, the node starts a looping glow tween. When set to any other
state, the tween is killed.

---

## UI Injection Pattern

`GameUI._apply_material_theme()` injects extra nodes into the VBoxContainer.
Final VBox order after injection:

```
Index 0  HBoxContainer "HeaderRow"   (injected — AlgoChip + StepChip)
Index 1  HSeparator                  (injected)
Index 2  HBoxContainer "ControlRow"  (injected — Reset button + Info button)
Index 3  HSeparator                  (injected)
Index 4  Label "MemoLabel"           (from scene)
Index 5  HSeparator                  (from scene)
Index 6  HBoxContainer "QueueRow"    (from scene)
Index 7  Button "AdvanceButton"      (from scene)
```

The info popup is a `Panel` appended to the `GameUI` Control (not the VBox), anchored
to cover the graph area, toggled by the Info button in ControlRow.

---

## Known Design Decisions

**Why `RefCounted` for algorithms?**
Algorithm objects hold no Godot scene state and are swapped frequently. `RefCounted`
gives automatic memory management without the overhead of `Node` lifecycle callbacks.

**Why `GameState` autoload instead of passing data directly?**
Scenes in Godot cannot pass data to each other during a scene change. An autoload
singleton is the idiomatic Godot 4 pattern for inter-scene communication. Keeping it
minimal (one integer) prevents it from becoming a shared global state mess.

**Why lazy deletion in Dijkstra, Prim's, and A*?**
The graph is small (6 nodes), making a proper decrease-key heap unnecessary. Lazy
deletion requires only a sorted array + a visited check on extraction — much simpler
to implement and to understand educationally. Each "stale entry" encountered produces
a visible, explanatory memo, turning the implementation detail into a learning moment.

**Why one neighbor per `advance()` call?**
Granular stepping lets learners watch every individual decision the algorithm makes.
Batching neighbor processing into one step would make the traversal harder to follow.

**Why `abs()` in Dijkstra and A*?**
Dijkstra's algorithm is undefined for negative edge weights. The design uses the
`-2` edge as a teaching contrast: Dijkstra and A* see it as `2` and find cost-9 paths,
while Bellman-Ford and Floyd-Warshall use the raw `-2` and find the true cost-5 path.

**Why is Floyd-Warshall 6 steps instead of edge-by-edge?**
Floyd-Warshall operates on a complete distance matrix and updates all pairs in each
k-iteration. There is no meaningful per-edge step to show. One k-iteration per step
exposes the key educational moment: watching the matrix improve as each intermediate
node is considered, culminating in the negative-edge discovery at k=4.

**Why does Kruskal use `_pending_visited`?**
When an edge is accepted into the MST, both endpoints should visually transition from
frontier to visited. A single `advance()` call can only return one StepResult. The
`_pending_visited` pattern defers the "visited" state change to the next advance(),
creating a two-step visual that mirrors the actual acceptance: "these nodes are joining
the MST" (frontier) then "they are fully in the MST" (visited).

---

## GDScript Pitfalls

| Pitfall | Notes |
|---|---|
| Missing `_initialized` in subclass | `AlgorithmBase` declares it, but the **subclass must also declare it** (or it inherits the base value, which is the same but makes the intent explicit). `GraphManager` checks `_active_algorithm._initialized`. |
| PQ sort ordering | `Array.sort()` on `[float, String]` pairs is lexicographic — cost at index 0 is compared first, which is correct for a min-heap. |
| `abs()` return type | `abs(int)` returns `int`; `abs(float)` returns `float`. Cast explicitly if needed. |
| `pop_front()` performance | O(n) — acceptable for n <= 6. |
| `Dictionary.keys()` order | In Godot 4, dictionary iteration order is **insertion order** — deterministic and matches the `DEPARTMENTS` definition order. |
| `Callable.call()` return type | `Callable.call()` returns `Variant`. Using `:=` to assign its result triggers a compile-time parse error because warnings are treated as errors in this project. Use explicit type declarations or avoid the assignment. |
| Unicode characters in web export | The bundled web font does NOT contain characters like `<-`, `*`, `>>`, `i`, or `x` as Unicode glyphs. Use ASCII equivalents: `<` not `<-`, `>>` not `>`, `[i]` not `i`, `x` not `x`. |
| `tween_method` with `Callable` | Use `Callable(self, "_method_name")` explicitly rather than a bare string. Looping tweens require `.set_loops()` on the Tween, not on individual tweeners. |
| `_draw()` in Main.gd | Main.gd's `_draw()` is called before child Node2D `_draw()` calls in scene tree order — stars render behind GraphLayer automatically. |
