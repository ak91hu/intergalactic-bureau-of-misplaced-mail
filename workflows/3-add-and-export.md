---
description: End-to-end workflow to implement a new graph algorithm, register it in all required locations, and produce a verified web export. Combines add-algorithm and fix-and-export into one flow.
---

# Add Algorithm and Export Workflow

Add a new graph algorithm as a fully playable option in the menu, verify it steps correctly through the graph, then produce a working web export with no regressions.

## Input

The user provides one of:
- An algorithm name and a brief description (e.g., "A* search — heuristic shortest path")
- A reference implementation to port from another language

## Execution Phases

Run each phase sequentially. Do NOT skip a phase or merge phases. Halt on any Jidoka condition.

---

### Phase 1: Gemba (Baseline Observation)
**Skill:** `scene-design` + `algorithm-implement` | **Goal:** Confirm the baseline before adding anything.

1. Read `AlgorithmBFS.gd` in full — canonical StepResult contract and phase structure.
2. Read `GraphManager.gd` — confirm `ALGORITHM_SCRIPTS` array length (current N).
3. Read `GameUI.gd` — confirm lengths of `ALGORITHM_FORM_CODES`, `ALGORITHM_NAMES`, `ALGORITHM_STRUCTURE_LABELS`, `ALGORITHM_INFO`.
4. Confirm all four arrays are the same length N.
5. Read `MenuScene.gd` — confirm `CARD_DATA` has N entries.

**Jidoka halt:** If array lengths differ, STOP. Fix the mismatch before proceeding.

**Output:**
```
Baseline confirmed:
  current algorithm count: [N]
  next index: [N]
  all arrays length N: YES
```

---

### Phase 2: Implement the Algorithm Class
**Skill:** `algorithm-implement` | **Goal:** Produce a correct AlgorithmX.gd.

1. Create `AlgorithmX.gd` extending `AlgorithmBase`.
2. Declare `var _initialized: bool = false` as the FIRST instance variable.
3. Implement all six methods in order: `get_name()`, `get_structure_label()`, `get_welcome_message()`, `initialize()`, `advance()`, `is_complete()`.
4. In `initialize()`: set up all algorithm state; set `_initialized = true` as the LAST statement.
5. In `advance()`: every code path must return a complete StepResult dict with all four keys (`state_changes`, `structure`, `message`, `is_complete`).
6. Use only ASCII in all string literals — no `←`, `★`, `▶`, `ℹ`, `↺`, `×`.

**Jidoka halt:** If any code path in `advance()` can return without `is_complete`, STOP. Fix it.

**Output:**
```
AlgorithmX.gd created:
  _initialized declared: YES
  initialize() sets it last: YES
  all advance() paths complete: YES
  no Unicode glyphs: YES
```

---

### Phase 3: Register in All Locations
**Skill:** `algorithm-implement` | **Goal:** Make the algorithm reachable from menu and game.

1. Add `preload("res://AlgorithmX.gd")` to `ALGORITHM_SCRIPTS` at index N in `GraphManager.gd`.
2. Add form code string to `ALGORITHM_FORM_CODES[N]` in `GameUI.gd`.
3. Add structure label string to `ALGORITHM_STRUCTURE_LABELS[N]`.
4. Add display name string to `ALGORITHM_NAMES[N]`.
5. Add info dict to `ALGORITHM_INFO[N]` with keys: `how_it_works`, `structure_explain`, `watch_for`, `complexity`.
6. Add card entry to `MenuScene.CARD_DATA` with keys: `short`, `full`, `desc`, `insight`, `complexity`, `difficulty` (1-3), `category`, `cat_color`.

**Jidoka halt:** After adding, confirm all five arrays are now length N+1 and all equal. If not, STOP.

**Output:**
```
Registration complete:
  ALGORITHM_SCRIPTS[N] set: YES
  All four GameUI arrays at N+1: YES
  MenuScene.CARD_DATA at N+1: YES
```

---

### Phase 4: Prepare Export
**Skill:** `godot-web-export` | **Goal:** Clean environment before export.

1. Verify `project.godot` contains `run/main_scene="res://MenuScene.tscn"` under `[application]` (no `config/` prefix).
2. Verify `export_presets.cfg` has exclude filter: `node_modules/*,web/*,package.json,package-lock.json,capacitor.config.json,*.md,export/*`.
3. Delete `.godot/exported/` to clear stale cache: `rm -rf .godot/exported`.
4. Confirm Godot executable path is accessible: `C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe`.

**Jidoka halt:** If the Godot exe is not found, STOP. Do not attempt headless export.

**Output:**
```
Export prep:
  run/main_scene key correct: YES
  exclude_filter set: YES
  .godot/exported/ cleared: YES
  Godot exe found: YES
```

---

### Phase 5: Export and Runtime Verification
**Skill:** `godot-web-export` | **Goal:** Produce and verify a working web build.

1. Run headless export:
   ```bash
   "C:/Users/Kovács Ákos/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe" \
     --headless --export-release "Web" "export/web/index.html" \
     --path "C:/testingClaude/myFirstGame"
   ```
2. Check terminal output — any `SCRIPT ERROR` line is a blocking parse error. Fix and re-export.
3. Verify `export/web/index.pck` size is under 100 KB.
4. Serve: `cd export/web && python server.py` (must use server.py, not `python -m http.server`).
5. Open `http://localhost:8080`, select the new algorithm card, step through at least 5 advances.
6. Confirm: node colors update, queue display updates, step counter increments, algorithm completes.

**Jidoka halt:** If `.pck` is over 100 KB, check if exclude filter is missing node_modules.

**Output:**
```
Export verification:
  No SCRIPT ERRORs in terminal: YES / NO (if NO, list)
  .pck size: [KB] — under 100 KB: YES / NO
  Browser console errors: NONE / [list]
  Algorithm selectable from menu: YES
  5 steps verified: YES
  Algorithm completes correctly: YES
```

---

## Final Output: Algorithm Addition Report

```markdown
# Algorithm Addition Report: [Algorithm Name]

## 1. Baseline
- **Previous algorithm count:** [N]
- **New index:** [N]

## 2. Implementation
- **File:** AlgorithmX.gd
- **All six methods implemented:** YES / NO
- **_initialized declared in subclass:** YES / NO
- **All advance() paths complete:** YES / NO
- **No Unicode glyphs:** YES / NO

## 3. Registration
- **ALGORITHM_SCRIPTS[N]:** YES / NO
- **All four GameUI arrays at length N+1:** YES / NO
- **MenuScene.CARD_DATA at length N+1:** YES / NO

## 4. Export
- **No SCRIPT ERRORs:** YES / NO
- **.pck size:** [KB]
- **Browser console errors:** NONE / [list]

## 5. Runtime
- **Algorithm steps correctly:** YES / NO
- **Step counter increments:** YES / NO
- **Reset returns to step 0:** YES / NO
```
