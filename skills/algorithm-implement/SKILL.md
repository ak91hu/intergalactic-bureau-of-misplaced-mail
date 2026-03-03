---
name: algorithm-implement
version: 1.0.0
level: technical
description: Use when adding a new graph algorithm to the game. Mandates the StepResult contract, AlgorithmBase subclassing, and GraphManager registration.
category: engineering
tags:
  - engineering
  - architecture
references:
  - name: godot-web-export
    path: ../godot-web-export/SKILL.md
  - name: scene-design
    path: ../scene-design/SKILL.md
---

# Algorithm Implement

Each graph algorithm in the game is a self-contained GDScript class extending `AlgorithmBase`. It produces `StepResult` dictionaries that the engine consumes without knowing the algorithm's internals. Adding a new algorithm requires: the class file, registration in `GraphManager`, and a UI label entry — no scene edits needed.

## Core Mandates

### 1. Implement the StepResult Contract
Every `initialize()` and `advance()` call must return a dictionary with exactly four keys.
- **Action:** Return `{"state_changes": [...], "structure": [...], "message": String, "is_complete": bool}` from both `initialize()` and `advance()`. Never return a partial dict.
- **Constraint:** NEVER emit signals from within an algorithm class. Signal emission is `GraphManager`'s responsibility via `_process_step_result()`.
- **Integration:** `GraphManager._process_step_result()` consumes this dict and emits all signals.

### 2. Declare _initialized and Implement is_complete()
`GraphManager.advance_algorithm()` routes to `initialize()` vs `advance()` based on `_initialized`. A missing declaration causes infinite re-initialization.
- **Action:** Declare `var _initialized: bool = false` as the first instance variable. Set `_initialized = true` as the last line of `initialize()`. Implement `is_complete()` returning the internal flag.
- **Constraint:** NEVER rely on the parent class's `_initialized` — subclasses must redeclare it.
- **Integration:** `GraphManager` reads `_active_algorithm._initialized` directly before each step.

### 3. Register in GraphManager and GameUI Constants
An algorithm not registered in both arrays is unreachable by the player.
- **Action:** Append the preloaded script to `ALGORITHM_SCRIPTS` in `GraphManager.gd`. Append matching entries to `ALGORITHM_FORM_CODES`, `ALGORITHM_STRUCTURE_LABELS`, `ALGORITHM_NAMES`, and `ALGORITHM_INFO` in `GameUI.gd`.
- **Constraint:** Array indices must be identical across all four arrays. An index mismatch produces wrong labels silently.
- **Integration:** `GameUI` reads these arrays by the same integer index emitted by `algorithm_selected`.

## Escalation & Halting

- **Jidoka:** If `advance()` is called without `initialize()` having run, the algorithm will crash on uninitialized variables. Halt and verify `_initialized` is declared and set.
- **Ho-Ren-So:** If a new algorithm produces incorrect traversal order, report the full step-by-step `state_changes` trace before debugging.

## Implementation Workflow

1. **Trigger:** A new graph algorithm is requested.
2. **Execute:** Create `AlgorithmX.gd` extending `AlgorithmBase`, implement all six methods (`get_name`, `get_structure_label`, `get_welcome_message`, `initialize`, `advance`, `is_complete`), register in `GraphManager` and `GameUI`.
3. **Verify:** Step through the algorithm manually to confirm `state_changes` color the correct nodes at each step.
4. **Output:** A fully playable algorithm accessible from the dropdown and info panel.
