# The Intergalactic Bureau of Misplaced Mail

> *"A package of unknown origin is somewhere in our facility. We will use the power of algorithms to locate it — one agonizing bureaucratic step at a time."*

A **Godot 4** interactive algorithm visualizer framed as a deeply dysfunctional intergalactic post office. Step through **9 classic graph algorithms** one decision at a time, watch nodes light up as they are discovered and finalized, and read bureaucratic memos that explain every algorithmic choice in plain terms.

Built without any external libraries — pure GDScript, programmatic UI, and `_draw()` rendering.

---

## What It Looks Like

```
        [REDUNDANCY DEPT.]  ← start
            /          \
         cost 3        cost 1
          /                \
   [FORMS]              [DELAYS]
    /      \                  \
cost 8   cost -2           cost 6
  /           \                 \
[STAMPS]    [LOST]──────────────┘
    \          /
  cost 1   cost 4
      \      /
   [DESTINATION]  ← end
```

The **-2 edge** (Forms → Lost) is the centrepiece of the graph. It lets you directly compare:
- **Dijkstra** (uses `abs(-2)=2`) → finds path cost **9**
- **Bellman-Ford / Floyd-Warshall** (uses real -2) → finds path cost **5**

Frontier nodes **pulse with an amber glow**. Examined edges **flash cyan** on screen. A **twinkling starfield** renders behind the graph.

---

## Algorithms

All 9 algorithms run on the same fixed 6-node directed weighted graph.

| # | Algorithm | Form Code | Category | Difficulty | What it finds |
|---|---|---|---|---|---|
| 1 | BFS — Breadth-First Search | BFS-9A | Traversal | Easy | Fewest-hop path |
| 2 | DFS — Depth-First Search | DFS-2B | Traversal | Easy | Any path (depth-first) |
| 3 | Topological Sort (Kahn's) | TOPO-7K | Ordering | Medium | Valid dependency order |
| 4 | Dijkstra | DIJ-1138 | Shortest Path | Medium | Shortest path (abs weights) |
| 5 | Bellman-Ford | BF-404 | Shortest Path | Hard | Shortest path (negative weights OK) |
| 6 | Prim's MST | MST-42 | Spanning Tree | Hard | Minimum Spanning Tree (greedy-local) |
| 7 | A* Search | ASTAR-H1 | Heuristic Search | Hard | Shortest path (heuristic-guided) |
| 8 | Floyd-Warshall | FW-INF | All-Pairs Path | Hard | All-pairs shortest paths |
| 9 | Kruskal's MST | KRU-7F | Spanning Tree | Medium | Minimum Spanning Tree (global-sort) |

**Notable contrasts built into the graph:**

| Comparison | Result |
|---|---|
| Dijkstra vs Bellman-Ford | Same path, costs 9 vs 5 — the -2 edge is the difference |
| Prim's vs Kruskal's | Same MST weight (11), opposite discovery strategies |
| A* vs Dijkstra | Same cost-9 path, A* skips "delays" entirely (h=10 keeps it out) |
| Bellman-Ford vs Floyd-Warshall | Both find cost 5, but FW computes all-pairs at once |

---

## How to Play

### In the Browser (pre-exported)

The game is pre-exported to `export/web/`. Serve it from that directory:

```bash
cd export/web
python server.py
```

Then open **http://localhost:8080** in Chrome or Firefox.

> Use `server.py` — not `python -m http.server`. The custom server sets the required
> `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers that
> Godot 4's WebAssembly runtime needs.

### In the Godot Editor

1. Install [Godot 4](https://godotengine.org/download/) (tested on 4.6.1 stable)
2. Open Godot → **Import** → select `project.godot`
3. Press **F5** to run

No export templates, plugins, or external dependencies required.

### Controls

| Action | How |
|---|---|
| Select algorithm | Click a card on the main menu |
| Step forward | Press **"Process Next Memo"** |
| Read explanation | Check the memo panel at the bottom |
| See internal state | Check the structure display (queue/stack/distances) |
| Pan the graph | Click and drag anywhere on the graph area |
| Reset | Press the **Reset** button |
| Get algorithm info | Press the **[i] Info** button |
| Return to menu | Press **< Menu** (top-left) |

---

## Re-Exporting for Web

If you change any `.gd` files, re-export and hard-refresh the browser:

```bash
# Requires Godot 4.6.1 export templates to be installed
Godot_v4.6.1-stable_win64.exe \
  --headless --export-release "Web" "export/web/index.html" \
  --path "C:/path/to/myFirstGame"
```

Then press `Ctrl+Shift+R` in the browser to hard-refresh.

---

## Architecture

The project uses a **Strategy pattern** — each algorithm is a self-contained `RefCounted` object that receives graph data and returns a `StepResult` dictionary on every call.

```
GraphManager
  ├── ALGORITHM_SCRIPTS[0..8]    ← preloaded algorithm classes
  ├── _active_algorithm          ← current AlgorithmBase subclass
  └── advance_algorithm()        ← routes to initialize() or advance()
           │
           │  emits signals:
           ├── node_state_changed(id, state)   → DepartmentNode.set_visual_state()
           ├── queue_updated(items)             → GameUI.update_queue_display()
           ├── step_message_changed(msg)        → GameUI.update_message()
           ├── edge_examined(from_id, to_id)   → Main._on_edge_examined()  [edge flash]
           └── algorithm_complete              → GameUI.disable_advance_button()
```

Every `advance()` call returns a `StepResult` dict:

```gdscript
{
    "state_changes": [{"id": "forms", "state": "frontier"}],  # node color updates
    "structure":     ["[f=9 g=3] — Bureau of Forms"],          # structure panel
    "message":       "RELAXATION: ...",                        # memo text
    "is_complete":   false,
    "examined_edge": {"from": "redundancy", "to": "forms"}     # optional: triggers edge flash
}
```

### File Map

| File | Role |
|---|---|
| `Main.gd` | Orchestrator — builds visuals, wires signals, starfield, edge flash |
| `GraphManager.gd` | Owns graph data + active algorithm, emits all signals |
| `GameUI.gd` | Bottom panel — memo, structure display, buttons, info popup |
| `DepartmentNode.gd` | Per-node visual — renders via `_draw()`, animated frontier glow |
| `MenuScene.gd` | Main menu — 9 clickable algorithm cards (3×3 grid) |
| `GameState.gd` | Autoload singleton — carries `selected_algorithm` between scenes |
| `AlgorithmBase.gd` | Base class (RefCounted) — defines the algorithm interface |
| `AlgorithmBFS/DFS/TopoSort/Dijkstra/BellmanFord/Prim/AStar/FloydWarshall/Kruskal.gd` | 9 algorithm implementations |

---

## Documentation

| Document | Audience | Contents |
|---|---|---|
| [`README.md`](README.md) | Everyone | This file — overview, setup, quick reference |
| [`PROJECT.md`](PROJECT.md) | Developers | Full architecture, script reference, signal flow, StepResult contract, adding new algorithms, known pitfalls |
| [`GAME_GUIDE.md`](GAME_GUIDE.md) | Players / learners | How to play, algorithm explanations, color guide, comparison tables, common questions |
| [`CLAUDE.md`](CLAUDE.md) | AI agents | Codebase instructions for Claude Code — scene structure, conventions, export commands |

---

## Visual Design

Galaxy / Material Design 3 dark palette — all defined as inline constants, no shared theme resource.

| Element | Color | Role |
|---|---|---|
| Background | `#080510` (deep space) | Scene background |
| Primary | `#8552FF` (nebula violet) | Buttons, borders, chips |
| Secondary | `#16E0D1` (cosmic cyan) | Edge flash, info highlights |
| Tertiary / Frontier | `#FFB81F` (amber) | Active / in-queue nodes |
| Nodes — default | `#120D21` | Undiscovered |
| Nodes — frontier | `#241404` + amber border + pulsing glow | Active |
| Nodes — visited | `#17141F` + dim border | Processed |

All rendering uses `_draw()` + programmatic `Line2D` — no sprites or textures.

---

## Project Structure

```
myFirstGame/
├── *.gd                        # All GDScript source files
├── *.tscn                      # Scene files (Main.tscn, DepartmentNode.tscn, MenuScene.tscn)
├── *.uid                       # Godot resource ID files (auto-managed)
├── project.godot               # Godot project configuration
├── export_presets.cfg          # Web export configuration
├── export/web/
│   ├── index.html              # Game launcher shell
│   ├── index.pck               # Compiled game scripts + scenes (~105 KB)
│   ├── index.wasm              # Godot engine (WebAssembly, ~36 MB — gitignored)
│   ├── index.js                # Godot JavaScript glue (~309 KB — gitignored)
│   └── server.py               # Dev server (sets required COOP/COEP headers)
├── README.md                   # This file
├── PROJECT.md                  # Developer documentation
├── GAME_GUIDE.md               # Player / learner guide
└── CLAUDE.md                   # AI agent instructions
```

---

## Contributing

The cleanest way to add a new algorithm:

1. Create `AlgorithmYourAlgo.gd` extending `AlgorithmBase` — implement `initialize()`, `advance()`, `is_complete()`.
2. Add a `preload()` entry to `GraphManager.ALGORITHM_SCRIPTS` and extend the `AlgorithmType` enum.
3. Extend the four parallel arrays in `GameUI.gd` (form code, structure label, name, info dict).
4. Add a card entry to `MenuScene.CARD_DATA`.
5. Re-export and verify.

See [`PROJECT.md`](PROJECT.md) for the full step-by-step guide and the `StepResult` contract.

---

*The Bureau assumes no liability for packages that arrive in the wrong century.*
