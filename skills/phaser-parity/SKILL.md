---
name: phaser-parity
version: 1.0.0
level: technical
description: Use when the Phaser 3 web rewrite (web/) must be brought into parity with the Godot 4 source of truth. Mandates StepResult↔stateChanges mapping, identical node positions, and matching algorithm logic.
category: engineering
tags:
  - engineering
  - phaser
references:
  - name: algorithm-implement
    path: ../algorithm-implement/SKILL.md
  - name: debug-algorithm
    path: ../debug-algorithm/SKILL.md
---

# Phaser Parity

The project has two parallel implementations: the Godot 4 source in the project root and a Phaser 3 web rewrite in `web/`. The Godot version is the **source of truth**. The Phaser version mirrors all algorithms, graph data, and node positions but uses JavaScript camelCase conventions and a different rendering pipeline.

## Core Mandates

### 1. StepResult ↔ stateChanges Field Mapping
GDScript and JavaScript use different naming conventions. The Phaser version must map exactly.

| Godot (GDScript) | Phaser 3 (JavaScript) |
|---|---|
| `state_changes` | `stateChanges` |
| `structure` | `structure` |
| `message` | `message` |
| `is_complete` | `isComplete` |
| `state_changes[i].id` | `stateChanges[i].id` |
| `state_changes[i].state` | `stateChanges[i].state` |

- **Action:** For each algorithm in `web/src/algorithms/`, confirm its `advance()` method returns an object with all four camelCase keys.
- **Constraint:** NEVER use snake_case in the Phaser version's StepResult equivalent. EventBus and GameUI.js depend on camelCase.

### 2. Node Positions Must Be Identical
The graph layout is fixed. Both versions use the same pixel coordinates.

```javascript
// web/src/ — must match Main.gd NODE_POSITIONS exactly
const NODE_POSITIONS = {
  redundancy:   { x: 640, y: 110 },
  forms:        { x: 380, y: 270 },
  delays:       { x: 900, y: 270 },
  stamps:       { x: 240, y: 440 },
  lost:         { x: 620, y: 440 },
  destination:  { x: 430, y: 600 },
};
```

- **Action:** Verify `web/src/MainScene.js` (or equivalent) defines positions matching `Main.gd NODE_POSITIONS`.
- **Constraint:** NEVER adjust node positions in Phaser without updating `Main.gd` and vice versa.

### 3. Edge Node Clearance Must Be 100
Both versions skip the first and last 100px of each edge so arrows do not overlap the node card.

- **Action:** Confirm `EDGE_NODE_CLEARANCE = 100` in both `Main.gd` (line ~30) and `web/src/MainScene.js`.
- **Constraint:** NEVER set a different clearance value in either version without updating both.

### 4. Graph Data — Weights Including Negative Edge
The graph has one negative weight edge (`forms → lost = -2`) required for Bellman-Ford.

```javascript
// web/src/ DEPARTMENTS or GRAPH must include:
// forms → lost: -2
```

- **Action:** Read `GraphManager.gd` DEPARTMENTS dict and compare to the JS graph data structure. Confirm `forms → lost` weight is `-2` in both.
- **Constraint:** NEVER normalise the negative weight in either version. It is intentional.

### 5. Algorithm Count and Order Must Match
Both versions have 6 algorithms at the same indices.

| Index | Algorithm |
|---|---|
| 0 | BFS |
| 1 | DFS |
| 2 | Topological Sort |
| 3 | Dijkstra |
| 4 | Bellman-Ford |
| 5 | Prim's MST |

- **Action:** List `web/src/algorithms/` files and confirm 6 files in matching order. Confirm the JS menu has 6 entries in the same order.
- **Constraint:** When a new algorithm is added to Godot, it MUST be added to the Phaser version at the same index.

## Escalation & Halting

- **Jidoka:** If a Phaser algorithm produces different step output than Godot for the same input, halt and run both side by side with console logging at each step. Do not assume the logic is equivalent until verified step-by-step.
- **Ho-Ren-So:** Report: (a) the algorithm name, (b) the first step where outputs diverge, (c) the Godot state_changes vs Phaser stateChanges at that step.

## Implementation Workflow

1. **Trigger:** A new algorithm was added to Godot and must be ported to Phaser, or a parity regression is reported.
2. **Execute:** Read the Godot algorithm file, port logic to JS using camelCase, verify node positions and edge clearance, add to Phaser menu.
3. **Verify:** Step through both versions in parallel for at least 5 steps. Confirm identical stateChanges at each step.
4. **Output:** A Phaser algorithm class that produces identical per-step output to its Godot counterpart.

## Poka-yoke Output Template

```markdown
# Phaser Parity Report: [AlgorithmName]

## 1. StepResult Field Mapping
- **All four camelCase keys present:** YES / NO
- **Missing keys (if NO):** [list]

## 2. Node Positions
- **NODE_POSITIONS matches Main.gd:** YES / NO
- **Mismatches (if NO):** [node: godot vs phaser]

## 3. Edge Clearance
- **EDGE_NODE_CLEARANCE = 100 in both:** YES / NO

## 4. Graph Data
- **forms → lost weight = -2 in Phaser:** YES / NO

## 5. Algorithm Index
- **Algorithm at correct index [N] in Phaser menu:** YES / NO

## 6. Step Verification
- **Steps verified:** [N steps]
- **First divergence (if any):** NONE / [step N: godot vs phaser]
- **Status:** PASS / FAIL
```
