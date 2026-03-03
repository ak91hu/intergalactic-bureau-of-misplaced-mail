# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start for Agents

| What you need | Where to look |
|---|---|
| Add a new algorithm end-to-end | `workflows/3-add-and-export.md` |
| Debug a broken algorithm | `skills/debug-algorithm/SKILL.md` |
| Re-produce the web export | `skills/godot-web-export/SKILL.md` or `workflows/2-fix-and-export.md` |
| Sync Godot ↔ Phaser 3 | `skills/phaser-parity/SKILL.md` |
| Design a new scene | `skills/scene-design/SKILL.md` |
| Understand StepResult contract | See **StepResult Dict Contract** below |

**Platform:** Windows 11. Shell is bash. Use Unix paths (forward slashes). Godot executable: `C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe`

**Re-export command:**
```bash
"C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe" \
  --headless --export-release "Web" "export/web/index.html" \
  --path "C:/testingClaude/myFirstGame"
```

---

## Project

**The Intergalactic Bureau of Misplaced Mail** — a Godot 4 2D educational game that visually steps through 6 graph algorithms in a galaxy/bureaucratic comedy style. Players click "Process Next Memo" to advance one step at a time.

---

## Architecture

### File Map

| File | Role |
|---|---|
| `GameState.gd` | Autoload singleton — persists `selected_algorithm: int` between scenes |
| `AlgorithmBase.gd` | Base class (extends RefCounted). Declares `var _initialized: bool = false` |
| `AlgorithmBFS/DFS/TopoSort/Dijkstra/BellmanFord/Prim.gd` | One file per algorithm — extends `AlgorithmBase` |
| `GraphManager.gd` | Delegates to active algorithm via `ALGORITHM_SCRIPTS` preload array |
| `MenuScene.gd` | Main menu. 6 clickable algorithm cards. Sets `GameState.selected_algorithm` then changes scene |
| `Main.gd` | Game scene orchestrator. Reads `GameState.selected_algorithm` in `_ready()` |
| `GameUI.gd` | Bottom panel Control. Step counter, algo chip, queue display, info popup |
| `DepartmentNode.gd` | Node2D prefab — renders via `_draw()` using `StyleBoxFlat.draw()` for rounded corners |

### Strategy Pattern

```
GraphManager
  ALGORITHM_SCRIPTS: Array = [preload(BFS), preload(DFS), ... preload(Prim)]
  _active: AlgorithmBase

  set_algorithm(type: int)  → instantiates ALGORITHM_SCRIPTS[type].new()
  advance_algorithm()       → routes to _active.initialize() or _active.advance()
  reset_algorithm()         → calls set_algorithm(_current_type)
```

Every algorithm subclass MUST:
1. Declare `var _initialized: bool = false` as the first instance variable
2. Set `_initialized = true` as the last line of `initialize()`
3. Return a complete StepResult dict from every code path in `advance()`

### StepResult Dict Contract

```gdscript
{
  "state_changes": [{"id": node_id, "state": "frontier"|"visited"}],
  "structure":     [String, ...],   # queue / stack / PQ / distances display
  "message":       String,          # bureaucratic flavour text
  "is_complete":   bool
}
```

### Signal Flow

```
Button press
  → GameUI.advance_requested
  → GraphManager.advance_algorithm()
  → node_state_changed(dept_id, state)   → Main._on_node_state_changed()
  → queue_updated(items)                  → GameUI.update_queue_display()
  → step_message_changed(msg)             → GameUI.update_message()
  → algorithm_complete()                  → GameUI.disable_advance_button()

GameUI.reset_requested → Main._on_reset_requested()
```

### GameUI Array Indices (must stay in sync)

`GameUI.gd` has four parallel const arrays — all indexed by algorithm type integer (0-5):

| Index | Algorithm |
|---|---|
| 0 | BFS |
| 1 | DFS |
| 2 | Topological Sort |
| 3 | Dijkstra |
| 4 | Bellman-Ford |
| 5 | Prim's MST |

Arrays: `ALGORITHM_FORM_CODES`, `ALGORITHM_NAMES`, `ALGORITHM_STRUCTURE_LABELS`, `ALGORITHM_INFO`

`GraphManager.ALGORITHM_SCRIPTS` must also be length 6 in the same order.

---

## Scene Structure

### `DepartmentNode.tscn`
```
Node2D  [script: DepartmentNode.gd]   ← root renamed "DepartmentNode"
```
No child nodes. All rendering is done in `_draw()`.

### `Main.tscn` (current state)
```
Node2D  "Main"              [script: Main.gd]
├── Node        "GraphManager"         [script: GraphManager.gd]
├── Node2D      "GraphLayer"           (panned by Main._unhandled_input)
│   ├── Node2D  "EdgesContainer"
│   └── Node2D  "NodesContainer"
└── CanvasLayer
    └── Control "GameUI"               [script: GameUI.gd]  (Full Rect)
        └── PanelContainer "BottomPanel"  (Bottom Wide, min-height 210, offset_top -210)
            └── MarginContainer  (margins 12/12/8/8)
                └── VBoxContainer
                    ├── Label       "MemoLabel"     (autowrap Word, min-height 48)
                    ├── HSeparator
                    ├── HBoxContainer "QueueRow"
                    │   ├── Label   "QueueTitle"    (text "THE QUEUE:")
                    │   └── Label   "QueueDisplay"  (autowrap, size_flags_horizontal Expand)
                    └── Button      "AdvanceButton" (text "Process Next Memo")
```

GameUI programmatically injects `HeaderRow` (AlgoChip + StepChip), `ControlRow` (Reset + Info buttons), and extra separators into the VBoxContainer via `_apply_material_theme()` called from `_ready()`.

### `MenuScene.tscn` (fully generated, no editor nodes)
All UI is built programmatically in `MenuScene._ready()`.

---

## Visual Style (Galaxy / MD3 Dark)

Galaxy palette — defined as inline constants in each file (no shared theme resource):

```gdscript
M_SURFACE     = Color(0.07, 0.05, 0.13)   # deep space background
M_SURFACE_V   = Color(0.12, 0.09, 0.22)   # elevated surface
M_PRIMARY     = Color(0.52, 0.32, 1.00)   # nebula violet
M_PRIMARY_C   = Color(0.15, 0.09, 0.36)   # primary container
M_SECONDARY   = Color(0.08, 0.88, 0.82)   # cosmic cyan
M_ON_SURF     = Color(0.93, 0.90, 1.00)   # primary text
M_ON_SURF_V   = Color(0.57, 0.52, 0.75)   # secondary text
M_OUTLINE     = Color(0.20, 0.16, 0.38)   # borders
SHADOW_COL    = Color(0.00, 0.00, 0.08, 0.70)
```

Corner radii: `RADIUS_BTN=8`, `RADIUS_CHIP=20`, `RADIUS_NODE=10`, `RADIUS_CARD=12`

Node states (also used as swatches in legend and info popup):
- `C_STATE_DEFAULT`  = `Color(0.07, 0.05, 0.13)` — undiscovered (dark surface)
- `C_STATE_FRONTIER` = `Color(1.00, 0.72, 0.12)` — active / in queue (amber)
- `C_STATE_VISITED`  = `Color(0.20, 0.20, 0.25)` — processed / done (dim)

---

## Known Gotchas

### 1. Button visibility — ALWAYS set content margins + focus state
`StyleBoxFlat` with zero content margins collapses the text area, making buttons appear blank.
Without a `focus` state override, Godot renders a bright white rectangle over the button after the first click.

**Rule:** Every button created in code must have:
```gdscript
style.content_margin_left = 12;  style.content_margin_right = 12
style.content_margin_top  = 5;   style.content_margin_bottom = 5
btn.add_theme_stylebox_override("focus", focus_style)  # MANDATORY
```

### 2. No Unicode glyphs in web export font
Characters like `←`, `★`, `▶`, `ℹ`, `↺`, `×` are NOT in Godot's bundled web font. They render as empty boxes.

**Rule:** Use only ASCII equivalents:
- `←` → `<` (e.g., `"< Menu"`)
- `★` → `*`
- `▶` → `>>`
- `ℹ` → `[i]`
- `↺` → remove or use plain text
- `×` → `x` or `[X]`

### 3. Callable.call() returns Variant — `:=` triggers parse error
In this project, warnings are treated as errors. `Callable.call()` returns `Variant`, and using `:=` with it causes a compile-time error.

**Rule:** Never assign the result of `Callable.call()` with `:=`. Use explicit type declaration or rewrite inline.

### 4. Stale web export
Changes to `.gd` files are not visible in the browser until a headless export is re-run. Always:
1. Run the headless export command (see Quick Start)
2. Hard-refresh the browser with `Ctrl+Shift+R`

### 5. Graph data — negative edge weight
`forms → lost` has weight `-2`. This is intentional for Bellman-Ford demonstration. Do not normalise it.

---

## Graph Data

6 nodes, directed weighted graph:

```
redundancy(640,110) → forms(380,270) [3]
redundancy          → delays(900,270) [1]
forms               → stamps(240,440) [7]
forms               → lost(620,440)   [-2]
delays              → lost            [5]
stamps              → destination(430,600) [1]
lost                → destination     [4]
```

Prim MST total weight: 11 (edges: redundancy-delays:1, redundancy-forms:3, forms-lost:2, lost-destination:4, stamps-destination:1)

---

## Testing

Run the full test suite headlessly:
```bash
"C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe" \
  --headless --script res://tests/runner.gd \
  --path "C:/testingClaude/myFirstGame"
```
Exit code 0 = all pass. Exit code 1 = at least one failure. FAIL lines print to stderr.

Test files live in `tests/`. `suite_base.gd` is the shared base class (`class_name TestSuite`) with
assertion helpers (`assert_eq`, `assert_true`, `assert_false`, `assert_has_key`, `assert_in_range`)
and the `_run_all_steps(algo)` driver. Each test file extends it via
`extends "res://tests/suite_base.gd"` (string-literal path, NOT `extends preload(...)` — that is invalid GDScript 4 syntax).

When adding a new algorithm, also add a `tests/test_<name>.gd` and register it in `SUITES` in
`tests/runner.gd`.

---

## Web Export

- Output: `export/web/`
- Server: `cd export/web && python server.py` (has COOP/COEP headers; do NOT use `python -m http.server`)
- Exclude filter in `export_presets.cfg`: `node_modules/*,web/*,package.json,package-lock.json,capacitor.config.json,*.md,export/*`
- Expected `.pck` size: under 100 KB

---

## Adding a New Algorithm

Use `workflows/3-add-and-export.md` for the full end-to-end process. Summary:
1. Create `AlgorithmX.gd` extending `AlgorithmBase`
2. Add `preload("res://AlgorithmX.gd")` to `GraphManager.ALGORITHM_SCRIPTS`
3. Extend all four parallel arrays in `GameUI.gd` (same index)
4. Add card entry to `MenuScene.CARD_DATA`
5. Re-export and verify
