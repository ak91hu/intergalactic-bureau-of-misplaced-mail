---
name: godot-web-export
version: 1.0.0
level: technical
description: Use when a Godot 4 web export must be produced or re-produced. Mandates correct project.godot key paths, exclude filters, and COOP/COEP header delivery.
category: engineering
tags:
  - engineering
  - lean
references:
  - name: algorithm-implement
    path: ../algorithm-implement/SKILL.md
  - name: scene-design
    path: ../scene-design/SKILL.md
---

# Godot Web Export

Godot 4 web exports produce a WebAssembly bundle that requires correct HTTP security headers (COOP/COEP) and a precisely keyed `project.binary` inside the `.pck`. Stale caches and wrong setting key paths silently produce broken exports that only fail at browser runtime.

## Core Mandates

### 1. Verify project.godot Key Paths Before Export
The runtime reads `application/run/main_scene`, stored in project.godot as `run/main_scene` under `[application]`. The common mistake is writing `config/run/main_scene` which maps to a nonexistent key.
- **Action:** Confirm `project.godot` contains exactly `run/main_scene="res://Main.tscn"` (no `config/` prefix) under `[application]`.
- **Constraint:** NEVER run a web export without verifying this key first. A syntactically valid but semantically wrong key produces a silent export that fails only in the browser.
- **Integration:** Feeds into the `fix-and-export` workflow Phase 1.

### 2. Clear Export Cache Before Re-export
The `.godot/exported/` directory caches compiled scenes. If the cache predates a structural change, the old binary is packed silently.
- **Action:** Delete `.godot/exported/` before any corrective re-export: `rm -rf .godot/exported`.
- **Constraint:** NEVER skip cache clearing when debugging a browser-side runtime error.
- **Integration:** Pairs with the headless export command in Phase 2.

### 3. Apply Exclude Filter to export_presets.cfg
Without an exclude filter, Godot packs `node_modules/`, `web/`, and markdown docs into the `.pck`, bloating it and risking data leakage.
- **Action:** Set `exclude_filter="node_modules/*,web/*,package.json,package-lock.json,capacitor.config.json,*.md,export/*"` in `export_presets.cfg`.
- **Constraint:** NEVER export with an empty `exclude_filter` when `node_modules/` exists in the project root.
- **Integration:** Verified by checking `.pck` size — game-only packs are under 100 KB for this project.

### 4. Serve with COOP/COEP Headers
Godot's WASM uses `SharedArrayBuffer`, which browsers block unless `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` are present.
- **Action:** Always serve `export/web/` using `server.py`, not `python -m http.server`.
- **Constraint:** NEVER instruct users to use the generic Python HTTP server for Godot web exports.
- **Integration:** `server.py` is located at `export/web/server.py` and already contains both headers.

## Escalation & Halting

- **Jidoka:** If the browser still shows a runtime error after a clean cache re-export, halt and read `index.js` line number from the error to identify the failing Godot engine call.
- **Ho-Ren-So:** Report the exact `project.binary` key path verified, the `.pck` file size, and the browser console error verbatim before proposing a fix.

## Implementation Workflow

1. **Trigger:** A web export is needed, or a browser runtime error is reported.
2. **Execute:** Verify `run/main_scene` key, clear `.godot/exported/`, confirm exclude filter, run headless export.
3. **Verify:** Check `.pck` file size (under 100 KB), serve with `server.py`, confirm no browser console errors.
4. **Output:** A working `export/web/` directory served at `http://localhost:8080`.

## Poka-yoke Output Template

```markdown
# Web Export Verification

## 1. Key Check
- **project.godot run/main_scene:** [value]
- **Correct (no config/ prefix):** YES / NO

## 2. Export
- **Cache cleared:** YES / NO
- **Exclude filter set:** YES / NO
- **.pck size:** [KB]

## 3. Runtime Verification
- **Server used:** server.py / other
- **Browser console errors:** NONE / [error text]
- **Status:** PASS / FAIL
```
