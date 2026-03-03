---
description: Add a new graph algorithm to the game as a fully playable, selectable option with correct UI labels, info panel content, and step-through behavior.
---

# Add Algorithm Workflow

Add a new graph traversal or optimization algorithm to the game so it is selectable from the menu, steps correctly through the graph, and has a matching info panel entry.

## Input

The user provides one of:
- An algorithm name and description (e.g., "A* search")
- A reference to an algorithm already implemented in another language to port

## Execution Phases

Run each phase sequentially. Document the findings for each phase.

---

### Phase 1: Gemba (Baseline Observation)
**Skill:** `scene-design` | **Goal:** Understand the existing pattern before adding anything.

1. Read `AlgorithmBFS.gd` in full to understand the exact StepResult contract and phase structure.
2. Read `GraphManager.gd` to confirm the `ALGORITHM_SCRIPTS` array index of the last entry.
3. Read `GameUI.gd` to confirm the last index of `ALGORITHM_FORM_CODES`, `ALGORITHM_NAMES`, `ALGORITHM_STRUCTURE_LABELS`, and `ALGORITHM_INFO`.
4. Confirm all four arrays have the same length.
5. **Output:** Confirmed baseline — next index N, all arrays length N.

---

### Phase 2: Implement the Algorithm Class
**Skill:** `algorithm-implement` | **Goal:** Produce a correct AlgorithmX.gd.

1. Create `AlgorithmX.gd` extending `AlgorithmBase`.
2. Implement all six methods: `get_name()`, `get_structure_label()`, `get_welcome_message()`, `initialize()`, `advance()`, `is_complete()`.
3. Declare `var _initialized: bool = false` as the first instance variable.
4. Ensure `initialize()` sets `_initialized = true` as its last statement.
5. Ensure every code path in `advance()` returns a complete StepResult dict.
6. **Output:** `AlgorithmX.gd` with all six methods implemented and all StepResult dicts complete.

---

### Phase 3: Register in GraphManager and GameUI
**Skill:** `algorithm-implement` | **Goal:** Make the algorithm reachable from the UI.

1. Add `preload("res://AlgorithmX.gd")` to `ALGORITHM_SCRIPTS` at index N in `GraphManager.gd`.
2. Add the form code string to `ALGORITHM_FORM_CODES` at index N in `GameUI.gd`.
3. Add the structure label string to `ALGORITHM_STRUCTURE_LABELS` at index N.
4. Add the display name string to `ALGORITHM_NAMES` at index N.
5. Add an info dict to `ALGORITHM_INFO` at index N with keys: `how_it_works`, `structure_explain`, `watch_for`, `complexity`.
6. Add the algorithm name to the `<option>` list in `MenuScene.gd` `CARD_DATA` and `GameUI` HTML option if applicable.
7. **Output:** All four arrays extended to length N+1 with matching indices.

---

### Phase 4: Shisa Kanko (Verification)
**Skill:** `godot-web-export` | **Goal:** Confirm no regressions before export.

1. Verify `load_steps` in all `.tscn` files is still correct (no new ext_resources added without incrementing).
2. Verify all four arrays in `GameUI.gd` are length N+1.
3. Verify `ALGORITHM_SCRIPTS` in `GraphManager.gd` is length N+1.
4. Clear `.godot/exported/` cache.
5. Run headless export and confirm `.pck` size is reasonable.
6. **Output:** Clean export, no console errors.

---

## Final Output: Algorithm Addition Report

```markdown
# Algorithm Addition Report: [Algorithm Name]

## 1. Baseline
- **Previous algorithm count:** [N]
- **New index:** [N]

## 2. Implementation
- **File:** AlgorithmX.gd
- **Methods implemented:** get_name, get_structure_label, get_welcome_message, initialize, advance, is_complete
- **_initialized declared:** YES / NO

## 3. Registration
- **ALGORITHM_SCRIPTS index N:** YES / NO
- **All four GameUI arrays extended:** YES / NO

## 4. Verification
- **Array lengths match:** YES / NO
- **Export size:** [KB]
- **Runtime errors:** NONE / [error]
```
