---
description: Diagnose and fix a broken Godot 4 web export so the game loads correctly in a browser with no runtime errors.
---

# Fix and Export Workflow

Resolve a broken Godot 4 web export — covering key path errors, stale cache, exclude filter misconfiguration, and missing COOP/COEP headers — then produce a clean export and verify it in the browser.

## Input

The user provides one of:
- A browser-side runtime error (e.g., "Can't run project: no main scene defined")
- A report that the exported page is blank or crashes on load
- A request to re-export after code changes

## Execution Phases

Run each phase sequentially. Stop at the first failing phase and fix the issue before continuing.

---

### Phase 1: Key Check (Gemba)
**Skill:** `godot-web-export` | **Goal:** Confirm `run/main_scene` is set correctly in `project.godot`.

1. Read `project.godot` and locate the `[application]` section.
2. Verify the key is exactly `run/main_scene="res://Main.tscn"` (or the current main scene).
3. **FAIL condition:** Key reads `config/run/main_scene` — this maps to a nonexistent settings path and Godot silently ignores it, causing "no main scene defined" at runtime.
4. **Fix:** Remove the `config/` prefix. The line must be `run/main_scene="res://SomeScene.tscn"`.
5. **Output:** Confirmed key value, PASS or FAIL.

---

### Phase 2: Autoload Check
**Skill:** `godot-web-export` | **Goal:** Confirm all autoloads declared in `project.godot` point to existing files.

1. Read the `[autoload]` section of `project.godot`.
2. For each entry (`Name="*res://Path.gd"`), confirm the file exists on disk.
3. **FAIL condition:** An autoload points to a file that does not exist → Godot parse error at startup.
4. **Fix:** Create the missing file or remove the stale autoload entry.
5. **Output:** List of autoloads and their existence status.

---

### Phase 3: Cache Clear
**Skill:** `godot-web-export` | **Goal:** Remove stale compiled scene cache before re-export.

1. Delete `.godot/exported/` directory: `rm -rf .godot/exported`.
2. Confirm the directory is gone or empty.
3. **Output:** Cache cleared — YES / NO.

---

### Phase 4: Exclude Filter Check
**Skill:** `godot-web-export` | **Goal:** Confirm `export_presets.cfg` excludes non-game content.

1. Read `export_presets.cfg` and find the `exclude_filter` key.
2. Confirm it contains `node_modules/*,web/*,*.md,export/*` at minimum.
3. **FAIL condition:** Empty `exclude_filter` when `node_modules/` exists → bloated `.pck`.
4. **Fix:** Set the exclude filter to the canonical value from the godot-web-export skill.
5. **Output:** Exclude filter value, PASS or FAIL.

---

### Phase 5: Headless Export
**Skill:** `godot-web-export` | **Goal:** Produce a fresh `.pck` and HTML bundle.

1. Run: `Godot.exe --headless --export-release "Web" "export/web/index.html" --path "."`
2. Confirm `export/web/index.html`, `index.pck`, `index.wasm`, `index.js` are all present.
3. Check `.pck` size — expect under 100 KB for this project.
4. **FAIL condition:** `.pck` over 150 KB → exclude filter not applied. `.pck` missing → export preset name mismatch.
5. **Output:** `.pck` size in KB, all files present YES/NO.

---

### Phase 6: Runtime Verification (Shisa Kanko)
**Skill:** `godot-web-export` | **Goal:** Confirm the export runs correctly in the browser.

1. Serve with `python server.py` from `export/web/` (NOT `python -m http.server`).
2. Open `http://localhost:8080` and check the browser console for errors.
3. **FAIL condition 1:** "Can't run project" → recheck Phase 1.
4. **FAIL condition 2:** SharedArrayBuffer error → wrong server, not sending COOP/COEP headers.
5. **FAIL condition 3:** Blank page with JS error → read `index.js` line number from the error.
6. **Output:** Console errors NONE / [verbatim error text], Status PASS / FAIL.

---

## Final Output: Fix and Export Report

```markdown
# Fix and Export Report

## 1. Key Check
- **run/main_scene value:** [value]
- **Correct (no config/ prefix):** YES / NO

## 2. Autoload Check
- **Autoloads declared:** [list]
- **All files exist:** YES / NO

## 3. Cache
- **Cache cleared:** YES / NO

## 4. Exclude Filter
- **Filter value:** [value]
- **Non-game dirs excluded:** YES / NO

## 5. Export
- **.pck size:** [KB]
- **All export files present:** YES / NO

## 6. Runtime
- **Server used:** server.py / other
- **Browser console errors:** NONE / [error]
- **Status:** PASS / FAIL
```
