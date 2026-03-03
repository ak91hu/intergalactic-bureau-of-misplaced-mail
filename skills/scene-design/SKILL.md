---
name: scene-design
version: 1.0.0
level: technical
description: Use when creating or modifying Godot 4 scenes without the editor. Mandates correct .tscn format, load_steps count, and programmatic UI injection over scene-tree UI nodes.
category: engineering
tags:
  - engineering
  - architecture
references:
  - name: godot-web-export
    path: ../godot-web-export/SKILL.md
  - name: algorithm-implement
    path: ../algorithm-implement/SKILL.md
---

# Scene Design

Godot 4 `.tscn` files use a text format where `load_steps` must exactly equal the number of `[ext_resource]` entries plus one (for the scene itself). `@onready` variable paths must match the scene tree node names exactly. Complex UI injected programmatically in `_ready()` or `_apply_theme()` is preferred over deeply nested scene trees, since the latter cannot be verified without the editor.

## Core Mandates

### 1. Keep Scene Trees Minimal
Scene trees define structural anchor nodes only. Visual styling, dynamic children, and programmatic UI belong in GDScript `_ready()` or theme methods, not in the `.tscn` file.
- **Action:** Define only structural nodes in `.tscn` (containers, anchors, named nodes that `@onready` references). Inject labels, buttons, and style boxes in code.
- **Constraint:** NEVER add more than two levels of unnamed or un-referenced children to `.tscn`. They become invisible technical debt with no way to verify correctness without the editor.
- **Integration:** This constraint keeps `.tscn` files readable and verifiable by text inspection alone.

### 2. Validate load_steps Before Export
`load_steps` equals `ext_resource count + 1`. A wrong value causes a silent parse error at runtime.
- **Action:** After editing a `.tscn`, count `[ext_resource]` lines and set `load_steps` to that count plus one.
- **Constraint:** NEVER add an `[ext_resource]` without incrementing `load_steps`.
- **Integration:** Verified immediately by opening the scene in Godot editor or by a headless parse check.

### 3. Pass Data Between Scenes via Autoload
Godot `change_scene_to_file()` does not support constructor arguments. Scene parameters must be passed via an autoload singleton.
- **Action:** Use `GameState.gd` (autoload) to store any data the destination scene needs before calling `get_tree().change_scene_to_file()`.
- **Constraint:** NEVER use global variables in individual scene scripts to pass inter-scene state. Use the designated autoload only.
- **Integration:** `GameState.selected_algorithm` is the current inter-scene parameter.

## Escalation & Halting

- **Jidoka:** If a scene fails to load with a parse error, halt and recount `load_steps` and `[ext_resource]` entries before any other investigation.
- **Ho-Ren-So:** Report the exact `.tscn` line that fails and the expected vs actual `load_steps` value.

## Implementation Workflow

1. **Trigger:** A new scene is needed or an existing scene must be modified.
2. **Execute:** Write minimal `.tscn` with correct `load_steps`, implement visual and dynamic content in GDScript `_ready()`.
3. **Verify:** Confirm `@onready` paths match node names in the `.tscn`. Confirm `load_steps` is correct.
4. **Output:** A `.tscn` file that parses correctly in headless export and produces the intended visual result.
