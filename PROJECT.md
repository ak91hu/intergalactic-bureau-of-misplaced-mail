# Developer notes: Misplaced Mail 3.2

## User feedback

BureauGuide is a shared Hungarian dispatcher card with a status heading, a short explanation and a concrete next action. MenuScene acknowledges persisted settings; CourierScene derives guidance from the real phase, parcel animation and playback state; TreeScene distinguishes manual answers, unchanged states after errors, help, practice and saved results; GameUI explains lab checkpoint waits and autoplay resumption. Detailed calculation/decision messages remain separate from the next-action guide. Guidance never advances the model or silently supplies a manual answer.

GameState.last_save_error records the actual ConfigFile result. Campaign and tree reports claim a successful save only after success; failures expose a retry. SAVE_PATH is an instance property with the existing user://bureau_progress.cfg default; empty optional path arguments resolve to that property. UI runners override it with separate test filenames before performing actions, protecting player saves even if a test aborts. The original lab uses one wrapped guidance label, updated once per frame, to fit its existing scrolling layout; the academy/campaign/tree screens use the shared card.

## Shared graphics

`BureauTheme` supplies the common palette, bundled font, rounded panels, button states, keyboard focus and scrollbars. Each UI root inherits its control theme. `BureauArt` caches small gradient textures and draws vector starfields, rounded map backgrounds, shaded planets and sealed envelopes. `BureauBackdrop` provides a noninteractive starfield; `BureauAtlas` draws the academy illustration; `BureauGlyph` draws topic icons. Artwork is original and needs no external image assets or shaders.

CourierBoard keeps its station positions, edge geometry, label collision rules and input hit areas; decorative layers only change the drawing. Selected lanes have a glow and a moving signal, and delivery adds a short envelope trail. TreeBoard uses the same planet drawing and highlights connections incident to the focused node. New background/illustration controls redraw at 10–20 Hz; CourierBoard caps idle decorative redraws at 20 Hz while actual parcel motion retains frame updates. Reduced motion stops star/illustration/route animation as well as the existing delivery/rotation animation. Academy sound and motion controls sit below the topic cards.

## Tree academy, audio and playback

TreeAlgorithms produces deep snapshots for ordinary BST, AVL and standard symmetric red-black insertion, followed by search and inorder traversal. TreeScene presents each comparison/repair as a Hungarian decision; TreeBoard draws the actual snapshot and animates node movement with reduced-motion support. Tree indices 0..2 are separate from the original graph registry. Three tiers each add nine lessons, for 36 academy lessons total. Independent tests check ordering/connectivity/parents at every frame and AVL/red-black invariants at stable states across fixed, sorted, reversed, duplicate and 60 shuffled inputs.

Tree progress uses separate tree_scores/tree_medals save sections. Manual lessons record personal bests; autoplay and rewind mark the session as practice and cannot award results. Campaign autoplay likewise marks the run as an unscored demonstration. Both honor speed/pause/guide controls; campaign timers wait for actual parcel animation. The original scored lab preserves learner checkpoints and resumes autoplay after each answer.

BureauAudio persists across scenes, fades a locally bundled Floating Cities MP3 at a quiet default volume, and attaches smooth synthesized clicks to BaseButtons. Music and effects have independent persisted toggles; music has a volume slider. Web music waits for a user gesture. Attribution is visible in the academy and included in both release packs and adjacent notices. tests/tree_ui.gd covers all nine tree manual/auto flows, all 27 campaign auto flows and all nine lab auto/checkpoint flows. Run all UI runners sequentially to preserve player saves.

## Learning-first courier campaign

The primary MenuScene is a Hungarian academy with nine learning goals, three tiers each, saved continuation and daily map variants. The original lab remains accessible through LabMenu. Algorithm indices are unchanged (0..8), and inter-scene parameters go through GameState.

| Campaign file | Responsibility |
| --- | --- |
| CourierLessons.gd | Hungarian rules, objectives, pseudocode, takeaways and standard complexities |
| CourierLevels.gd | Deterministically seeded 6–8-node variants, signed/unsigned costs, recipients and closed lanes |
| CourierGraph.gd | Active-lane-aware neighbors, edges and route costs |
| CourierSolver.gd | Reference all-pairs, hop paths, MST and consistent geometric heuristic |
| CourierSession.gd | Pure decision state machine, actual execution cost, hints, undo/replan and report |
| CourierScene.gd | UI/controller, live data/formulas/code, navigation, input and audio |
| CourierBoard.gd | Curved directed map, collision-aware labels, matrix, hit testing and actual parcel travel |
| tests/test_courier.gd | Generated missions, independent optimum checks and learning/execution consequences |
| tests/courier_ui.gd | Full 27-mission UI flows, map/edge/matrix input and rendered screenshots |

Briefing leads to manual algorithm decisions, execution and a learning report. Optional automata mode demonstrates correct decisions without awarding scores. Wrong learning choices explain why and preserve algorithm data; ties are accepted. BFS/DFS use FIFO/LIFO and discover neighbors on insertion, DFS in reversed alphabetical order. Dijkstra/A* explicitly compare each relaxation. Bellman–Ford scans complete passes and checks reachable negative cycles before path reconstruction. Topological sort accepts any zero-indegree choice.

Prim accepts only crossing edges from its growing tree; Kruskal unites components and skips cycle edges. Legal non-greedy edges really change tree/cost and receive learning feedback. Floyd updates all pairs for each chosen intermediate point and flags a negative diagonal. Tier 2 dispatches A→H and B→G using the same matrix.

Generated signed maps are DAGs without negative cycles; custom test maps exercise detection. A* h is normalized geometric distance to the recipient multiplied by the minimum active edge cost/distance ratio. Triangle inequality proves consistency. Tests verify consistency and admissibility; decisions compare full precision, displays round decimals.

After planning, the player chooses actual adjacent delivery steps. Budget is optimum plus tier slack 2/1/0 (4/1/0 for networks), except DFS's V+2-hop allowance. Failure is checked at arrival or a dead end, so a signed route may temporarily exceed budget before a rebate. Undo restores deep snapshots but keeps help/mistake counters. Replan preserves learned distances or clears the network. DFS reports compare with BFS without claiming its route is shortest.

GameState adds courier_scores/courier_medals sections keyed algorithm:tier, while preserving lab scores, medals and settings. Bests and medals never decrease; XP sums bests. The grade/score rules are in GAME_GUIDE.md.

Independent campaign references enumerate simple paths and spanning edge subsets, rather than merely comparing two greedy implementations. Model tests cover 81 generated missions. UI tests play 27 base lessons and check actual node/edge/matrix clicks, next/fresh/home navigation, shortcuts, guide blocking, budget recovery, pinned report controls, label collisions on regenerated/compact maps, and curved parcel animation/input locking. UI runners use isolated test saves and run sequentially.

Inter is bundled with its OFL license for Hungarian and math glyphs. See THIRD_PARTY.md. This intentionally grows packs beyond the historical skill's 100 KB example; fonts are required for reliable typography. Export filters still exclude tests, scripts, QA and documentation. Desktop pack loading does not verify browser WebAssembly/WebGL gameplay; record browser checks separately.

## Runtime and builds

Godot 4.7.2 stable and matching standard export templates; no third-party runtime dependencies. `.godot-version` pins CI, while `project.godot` declares the 4.7 feature level. Compatibility rendering serves desktop and WebGL 2. The web preset uses the single-threaded template. `scripts/server.py` serves WASM MIME, COOP/COEP and no-cache headers.

Run `scripts/build.ps1 -Godot <engine path>` to import, test and build both release targets. `-Target Tests`, `Web` and `Windows` restrict output. CI does the same on Linux using official engine/template downloads and pinned GitHub actions. Local build verification is separate from running the remote workflow.

## Original lab ownership

| File | Responsibility |
| --- | --- |
| `GameState.gd` | Autoload: selected algorithm/mode, progress and preferences |
| `BureauTheme.gd` | Shared palette, labels, focus and container helpers |
| `LabMenu.gd` | Original mission desk, nine keyboard-focusable cards and settings |
| `GraphManager.gd` | Graph, algorithm registry, timeline, cursor and rewind |
| `MissionSession.gd` | Three checkpoints per trace, answers, hints, score and medals |
| `Main.gd` | Mission orchestration, map, zoom/pan, answer selection and audio |
| `GameUI.gd` | HUD, playback controls, shortcuts and algorithm reference |
| `DepartmentNode.gd` | Node drawing with textual state and optional pulse |
| `Algorithm*.gd` | Nine deterministic stepwise algorithm implementations |
| `tests/runner.gd` | Algorithm contract, outputs, gameplay and persistence tests |
| `tests/ui_smoke.gd` | Complete scene flows and optional rendered screenshots |

Scenes stay small. MenuScene uses a full-rect Control; Main owns graph layers, manager and HUD. `load_steps` matches resource count plus one.

## Original lab algorithms and timeline

Registry order: BFS, DFS, Topological Sort, Dijkstra, Bellman-Ford, Prim, A*, Floyd-Warshall, Kruskal (0..8). Keep registry, lab cards, campaign lessons, HUD/reference entries and rules aligned.

An algorithm extends AlgorithmBase, sets the inherited `_initialized` flag in initialize(), and returns:

```gdscript
{
    "state_changes": [{"id": "forms", "state": "frontier"}],
    "structure": ["Forms"],
    "message": "Dispatch text",
    "is_complete": false,
    # optional: "examined_edge": {"from": "redundancy", "to": "forms"}
}
```

GraphManager generates and deep-copies the complete trace with a 2000-step guard. Each frame stores cumulative node states for rewind. The cursor starts at -1. Advance/rewind emit legacy signals and `frame_changed(frame, step, total)`. UI counters come from the cursor, not button clicks. The algorithm instance is already complete after trace generation; consult the cursor for live playback state.

Completed lab shortest-path frames highlight HQ -> Forms -> Lost -> Delivery on the fixed six-node graph. MST edges come from the actual tree. Fixed highlighting is confined to the lab; courier paths come from generated graph data.

## Original lab checkpoints

MissionSession selects three separated processing events from the trace. Kruskal uses examined edges. Bellman-Ford and Floyd-Warshall use three curated cost/concept questions at timeline milestones. Correct options come from the trace; answer positions and distractors are shuffled.

Main intercepts advancement before a checkpoint frame. The HUD disables advancing and auto-play, then accepts one valid answer. MissionSession rejects duplicates and invalid choices, records points and resolves the checkpoint. Main reveals the frame and feedback. Hints are charged once per checkpoint. Completion records a best score/medal; practice never records results.

## Persistence and QA

`user://bureau_progress.cfg` stores scores, medals, sound and reduced motion using ConfigFile. Malformed individual scores are ignored and numeric values clamped. Replays take maximum scores and medals.

Persistence tests use a separate file. Scene runners also select separate save files before making changes; they never write results/settings to the real player file. Run them sequentially. Screenshot mode needs a renderer and writes under ignored `qa/`; headless mode validates flows and geometry, not pixels. The browser's actual WebAssembly/WebGL runtime requires a separate browser check.

The UI uses a 1280x900 design viewport and a 1000x700 minimum native window. Menu/sidebar scroll when needed; campaign report actions stay pinned. Reduced motion disables pulses, packet animation and twinkling. Interface sounds are synthesized in memory; the ambient recording is bundled locally. Run scripts/build.ps1 to verify all four test entry points, and inspect rendered QA after layout changes. See VALIDATION.md for current release evidence.
