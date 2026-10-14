# Agent guidance

This is a Godot 4.7.2 game with a Hungarian 27-lesson courier campaign and the original nine-algorithm lab. Use current README and PROJECT.md; historic skill examples describe the fixed visualizer.

Version 3.1 also has nine BST/AVL/red-black tree lessons (TreeAlgorithms/TreeScene/TreeBoard) and the persistent BureauAudio autoload. Tree indices 0..2 are separate from the unchanged graph registry. Run tests/tree_ui.gd after UI/playback/audio changes. Demos and rewinds must never award medals or XP. Tree snapshots must preserve ordering; every completed insertion must satisfy the relevant balance/color invariants. Keep music attribution in the menu and release packs.

- Use `scripts/build.ps1 -Godot <path> -Target All|Tests|Web|Windows`. Matching 4.7.2 export templates are required; avoid contributor-specific absolute paths.
- Keep algorithms deterministic and preserve the lab StepResult contract. Run all four test entry points after gameplay changes.
- Learning has priority: explain actual data, formulas and decisions. Keep CourierSession independent of UI/autoload; preserve tie handling, hints, undo/replan and real cost consequences. Independently verify generated graph optimums and consistent A* heuristics; guard negative-cycle path reconstruction.
- Indices are 0..8: BFS, DFS, Topological Sort, Dijkstra, Bellman-Ford, Prim, A*, Floyd-Warshall, Kruskal. Align registry, menu, HUD/reference and mission rules when adding algorithms.
- GraphManager precomputes traces. Its algorithm is already complete during playback; the cursor and final frame control live completion. Snapshots must be deep copies.
- In the original lab preserve Forms -> Lost = -2 and its displayed signed/absolute policies. Campaign maps use generated displayed costs and reconstruct actual paths. MST lanes are undirected.
- Use BureauTheme for margins, readable text and keyboard focus. Keep scenes minimal and match @onready paths with tree names.
- Reject duplicate/invalid answers. Preserve both save namespaces and personal bests, keep lab practice unscored, and restore/isolate player saves in tests. Run UI runners sequentially.
- Inspect rendered screenshots for layout changes. Run all three UI scripts with a renderer and `-- --screenshots`: ui_smoke, courier_ui and tree_ui. Inspect generated dense maps, compact layouts and reports. Headless tests cannot verify pixels.
- Generated export/, qa/ and .godot/ stay untracked. Exclude tests/scripts/QA/docs from packs and include the bundled Inter license. The larger font-containing pack intentionally exceeds old 100 KB guidance. Publish only when requested.
- Preserve MenuScene as application/run/main_scene. Re-export after changes and serve with scripts/server.py or its copy under export/web/.
