---
name: debug-algorithm
version: 1.0.0
level: technical
description: Use when a graph algorithm step-through produces wrong node states, crashes, or missing messages. Mandates StepResult validation, state_changes tracing, and GDScript parse-error diagnosis.
category: engineering
tags:
  - engineering
  - debugging
references:
  - name: algorithm-implement
    path: ../algorithm-implement/SKILL.md
  - name: godot-web-export
    path: ../godot-web-export/SKILL.md
---

# Debug Algorithm

Algorithm bugs fall into four categories: (1) wrong or missing StepResult fields, (2) incorrect state machine transitions, (3) GDScript parse errors that prevent export, and (4) visual rendering issues caused by font or style constraints. Each requires a different diagnostic approach.

## Core Mandates

### 1. Validate the StepResult Dict on Every Code Path
Every `advance()` return must be a complete dict. A missing key crashes `GraphManager` silently — the signal fires with `null` and the UI freezes.

- **Action:** Grep `advance()` in the suspect algorithm file. Confirm every `return` statement includes all four keys: `state_changes`, `structure`, `message`, `is_complete`.
- **Constraint:** NEVER leave a code path that returns only a partial dict. Use a `_make_result()` helper or inline all four keys explicitly.
- **Integration:** Run against `AlgorithmBFS.gd` as a reference — its `advance()` is the canonical correct implementation.

### 2. Trace state_changes for Each Step
Wrong node colors usually mean `state_changes` emits an incorrect id or state string.

- **Action:** Add a temporary `print("state_changes: ", result["state_changes"])` at the top of `GraphManager.advance_algorithm()`, run the algorithm step by step, and compare printed ids against `NODE_POSITIONS` keys in `Main.gd`.
- **Valid state strings:** `"default"`, `"frontier"`, `"visited"`. Any other string is silently ignored by `DepartmentNode.set_visual_state()`.
- **Constraint:** NEVER assume the id string matches the display name. Ids are lowercase short keys: `"redundancy"`, `"forms"`, `"delays"`, `"stamps"`, `"lost"`, `"destination"`.

### 3. Check _initialized Across Reset
The most common crash after a reset: `_initialized` is not redeclared in the subclass, so `AlgorithmBase._initialized` is shared and remains `true` after `reset_algorithm()` instantiates a new object — but if `initialize()` was never called properly, the subclass may branch into `advance()` prematurely.

- **Action:** Confirm the suspect algorithm file contains `var _initialized: bool = false` as its own instance variable (not just inherited). Then confirm `initialize()` sets it to `true` as its last statement.
- **Constraint:** NEVER rely on the inherited value from `AlgorithmBase`. Each subclass must declare its own.

### 4. Diagnose GDScript Parse Errors Before Export
A parse error in any `.gd` file silently fails the export — the old `.pck` is kept and the browser shows stale content.

Common causes in this project:
- **Callable.call() with :=** — `Callable.call()` returns `Variant`; `:=` cannot infer `Variant`. Fix: use explicit type or inline the code.
- **Unicode in string literals** — characters like `←`, `★`, `▶`, `ℹ`, `↺` in string literals are valid GDScript but render as empty boxes in the web export font. They are NOT parse errors but look like missing content at runtime.

- **Action:** Run the headless export and read the terminal output. Any `SCRIPT ERROR` line with a file and line number is a parse error. Fix it, then re-export.
- **Constraint:** NEVER push a web export without checking terminal output for `SCRIPT ERROR`.

### 5. Detect Unicode Glyph Rendering Failures
If buttons or labels appear blank or show squares, the cause is a Unicode character that is not in Godot's bundled web font.

- **Action:** Grep all `.gd` files for non-ASCII characters: `grep -rn "[^\x00-\x7F]" *.gd`. Replace each match with an ASCII equivalent (see table below).
- **Replacement table:**
  - `←` → `<`
  - `★` → `*`
  - `▶` → `>>`
  - `ℹ` → `[i]`
  - `↺` → remove or use plain text
  - `×` → `x` or `[X]`
- **Constraint:** NEVER use Unicode characters in button labels or algorithm message strings. Stick to ASCII.

## Escalation & Halting

- **Jidoka:** If `advance()` returns a complete dict but `queue_updated` still fires with wrong data, halt and read `GraphManager.advance_algorithm()` to verify the signal call uses `result["structure"]` not `result["queue"]`.
- **Ho-Ren-So:** Before reporting a fix, state: (a) the exact file and line of the bug, (b) which StepResult field was wrong or missing, (c) the fix applied, and (d) which step number reproduces the issue.

## Implementation Workflow

1. **Trigger:** Algorithm produces wrong node colors, freezes the UI, or shows missing text.
2. **Execute:** Validate all StepResult returns, trace state_changes, check `_initialized`, run headless export for parse errors.
3. **Verify:** Step through the full algorithm from init to complete with no console errors, correct colors, and correct queue display.
4. **Output:** A passing algorithm with a verified debug report.

## Poka-yoke Output Template

```markdown
# Algorithm Debug Report: [AlgorithmName]

## 1. StepResult Validation
- **All advance() paths return complete dict:** YES / NO
- **Missing keys (if NO):** [list]

## 2. state_changes Trace
- **Incorrect ids found:** NONE / [list]
- **Invalid state strings found:** NONE / [list]

## 3. _initialized Check
- **Subclass declares own _initialized:** YES / NO
- **initialize() sets _initialized=true last:** YES / NO

## 4. Parse Errors
- **Headless export SCRIPT ERRORs:** NONE / [file:line error]
- **Unicode grep matches:** NONE / [file:line char]

## 5. Outcome
- **Bug root cause:** [description]
- **Fix applied:** [description]
- **Steps verified:** [N steps, all correct]
```
