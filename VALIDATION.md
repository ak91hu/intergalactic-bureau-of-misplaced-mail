# Verification: 2026-10-14 — version 3.2.0

## Current release: communicative guidance

- Added a contextual Hungarian dispatcher card to the academy, courier missions and tree lessons. It separates the current explanation from the next action, covers all campaign phases, explains parcel input locks and autoplay/pause, reassures users after recoverable mistakes, and confirms saved results/settings. The original lab has a wrapped guidance field for checkpoint waits and resumed playback.
- Final full build: model **40280**, headless lab **265**, headless courier **8552**, tree/audio/autoplay **1185 checks**, all with **0 failures**; **50282 total successful source checks**. Both rebuilt release packs pass **22 isolated checks** each, including current version 3.2.0 and visible academy guidance. Web PCK: **6746064 bytes**; Windows executable: **115919328 bytes**. Windows standalone headless startup exits 0; localhost:8080 serves the current HTML/PCK with HTTP 200 and no-cache headers.
- Actual save results are surfaced through GameState.last_save_error. Failed campaign/tree result saves display a warning and an operational retry; they do not claim success. Integration checks exercise failure display and recovery, unchanged state after wrong answers, settings confirmation, parcel departure/arrival and lab checkpoint explanations.
- Rendered verification on Intel UHD Graphics 620/OpenGL 3.3: lab **270**, courier **8569**, tree/audio/autoplay **1195 checks**, all with **0 failures**. Inspected briefing, frontier/decision controls, checkpoint help, tree rotation explanations, result/pause cards, settings confirmation and compact layouts. The next-action guide remains visible while detailed content scrolls.
- A long QA flow exposed a native engine crash with the new nested guide panel in the legacy lab layout. The final lab implementation uses a plain wrapped label and batches its updates; the same complete manual/auto/campaign/lab flow subsequently passed headless and with a renderer. No failing version was exported over the running release.
- An early aborted UI test, before save isolation was added, left generated scores/settings in the **desktop** progress file. The observed file was preserved as `qa/communication-progress-backup.cfg`; browser storage was not involved. All three UI runners now switch to separate test save paths before making changes, including settings and result saves, so subsequent interruptions cannot overwrite player progress.
- Browser gameplay retains the earlier limitation: no browser is connected. Native rendered flows and release-pack checks are distinct from WebAssembly/WebGL/browser-audio testing.

## Earlier 3.1 release evidence

## Trees, audio and autoplay

- Added three independently playable tree topics (BST, AVL and red-black), three tiers each, for 12 topics and 36 academy lessons. Traces include actual comparison/insert/rotation/recolor/search/inorder snapshots, Hungarian decisions, recoverable mistakes/hints, undo, animation and a learning report. Tree results use separate save sections and preserve previous personal bests.
- Model suites: **40279 passed, 0 failed**. Of these, 31949 check tree ordering, connectivity, parent pointers, rotation order preservation and stable AVL/red-black invariants. Inputs include all lesson tiers and variants, mirrored/simple/double rotations, red-uncle repairs, sorted/reversed/duplicate keys and 60 deterministic shuffled sets. Balanced heights and found/missing searches are checked independently of the model's traversal functions.
- Headless UI: original lab **265 checks**, campaign **8519 checks**, new tree/audio/autoplay runner **1128 checks**, all with **0 failures**. Total model + headless UI: **50191 successful checks**. The new runner completes all nine tree lessons manually and automatically, all 27 campaign demonstrations, and all nine original lab auto/checkpoint flows. It checks timer delay, guide pauses, invalid/wrong answers, compact layout, persistence, no scoring during demonstrations, ambient recording/looping, volume control and zero-amplitude sound-effect endpoints. Player saves are restored.
- Rendered UI on Intel UHD Graphics 620/OpenGL 3.3: lab **270**, campaign **8536**, tree/audio/autoplay **1138 checks**, all with **0 failures**. Inspected academy/music controls, tree tier picker, both rotation directions, red-black colors and NIL marks, reports, 1000×700 tree/campaign views and the visible campaign auto/speed controls. Explanation panels scroll within their allotted space.
- Audio: locally bundled unchanged **Floating Cities** by Kevin MacLeod, CC BY 4.0, quiet persisted volume and separate music/effect toggles. Music fades and continues across scenes; web playback waits for input. Short synthesized effects use smooth envelopes and remain attenuated. Credits are shown in the academy and included inside and beside both exports. Device/speaker listening was not independently verified.
- `scripts/build.ps1 -Target All` completed: all four test entry points, cleared in-project export cache, rebuilt web and Windows, and **21 isolated checks per release pack**, including the soundtrack/audio autoload, tree scene and attribution. Web PCK: **6731724 bytes**; Windows executable: **115904984 bytes**. WASM remains **39514754 bytes**. Windows binary startup with `--headless --quit-after 10` exits **0**, without engine errors.
- The running local server at **http://localhost:8080/** returns **HTTP 200** for HTML, current PCK and WASM. Current pack length is 6731724; delivery retains WASM MIME, no-cache and COOP/COEP headers.
- Browser gameplay remains **unverified**: the browser inventory is empty and the in-app browser reports `Browser is not available: iab`. Desktop rendered and isolated pack checks do not substitute for an actual WebAssembly/WebGL/browser-audio run.
- Git whitespace check passed. No commit, GitHub upload or remote deployment was performed.

## Earlier 3.0 release evidence

Engine: official Godot 4.7.2 stable, ed1daf0bf, with matching standard templates. The official download page still lists 4.7.2 as stable on this date.

## Tests and rendered evidence

- Algorithm, timeline, mission and persistence suites: **8322 passed, 0 failed**. Campaign contributes 5944 assertions across **81 generated missions** (9 algorithms × 3 tiers × 3 variants). Optimums are checked by independent exhaustive simple-path and spanning-edge-subset references. Tests also cover A* admissibility/consistency, topological dependencies, signed costs, custom negative cycles and actual budget/undo/replan consequences.
- Original lab headless UI: **265 checks, 0 failures**. All nine checkpoint missions, invalid/duplicate answers, numeric/map input, auto-play, restart, guide, saved results and practice rewind remain working.
- Campaign headless UI: **8519 checks, 0 failures**. All **27 base lessons** complete through actual buttons and map node/edge/matrix-header clicks. Next/fresh/home navigation, hints, guides, shortcut/undo behavior, persistent report records, real animation locking/curved travel and expensive-route recovery are exercised.
- Campaign rendered UI on Intel UHD Graphics 620/OpenGL 3.3: **8536 checks, 0 failures**. Inspected academy/tier picker, briefing, queue, relaxation, matrix, planned route, network, two-sender report, guide, in-flight straight/curved parcels, budget recovery, regenerated mirrored graph and 1000×700 compact view. Edge labels avoid nodes, captions and other labels; report buttons stay pinned.
- Original lab rendered UI: **270 checks, 0 failures**. Existing lab is preserved and reachable.
- Inter glyph checks include Hungarian ő/ű/á/é and ∞/→/≤/×. Font and engine notices accompany the releases.
- Git diff whitespace check: passed.

## Release verification

- `scripts/build.ps1 -Target All` imports, runs all three source test entry points, clears the checked in-project export cache, builds both targets and checks each rebuilt pack.
- Isolated web and embedded Windows packs each pass **16 checks** for current version/main scene/autoload, font/engine notices, academy/campaign/lab loading and exclusion of development files. Pack checks use the release directory as resource root so source files cannot mask a packaging omission.
- Final artifact sizes: web PCK **805364 bytes**, WASM **39514754 bytes**, Windows executable **109978624 bytes**. The licensed font and engine notices intentionally exceed the historical 100 KB pack example.
- The released web pack also passes the complete **8519-check campaign UI runner** in desktop Godot using an external test script; test scripts remain excluded from the distributed pack.
- Windows executable startup with `--headless --quit-after 10` exits **0** without engine errors. The standalone exported binary's normal startup is tested separately from pack flows in the full engine.
- HTTP delivery of HTML, WASM, PCK and JS: **200**, correct MIME types, COOP `same-origin`, COEP `require-corp`, valid WASM/PCK signatures. This check used a temporary Node HTTP server with the same delivery headers; the provided Python server's configuration was inspected.
- Browser WebAssembly/WebGL gameplay: **not verified**. No browser is connected. Earlier automatic approval review rejected a separate Chrome test process with “blocked by policy”; it was not retried. Desktop pack checks do not replace browser gameplay.
- Remote GitHub Actions: **not run**. Source changes remain local and uncommitted on `feat/playable-missions`; no GitHub upload or deployment was performed.

## Completion against UPGRADE_PLAN.md

| Requirement | Implemented and checked evidence |
| --- | --- |
| 1. Real decisions/consequences | Manual routes and trees affect cost/outcome; expensive route/tree failure, repair and replan tests |
| 2. Variation and progression | Seeded 6/7/8-node tiers, optional/closed connections, costs/recipients; 81 model missions and fresh-map UI navigation |
| 3. Complete short missions | Briefing → manual planning → delivery/network/order execution → learning report; all 27 UI flows |
| 4. Algorithm-specific mechanics | FIFO/LIFO, indegrees, relaxation, g/h/f, all-pairs, crossing edges and component/cycle decisions |
| 5. Understandable learning | Hungarian rules/feedback, live data/formulas, highlighted/full pseudocode, complexity and takeaways; inspected rendered states |
| 6. Recoverable learning | Hints charged once per decision, deep undo, replan, guide and failed-budget UI checks |
| 7. Compatible progress | Separate campaign sections, legacy scores retained, personal bests and recommended lesson; 21 persistence assertions |
| 8. Readable/animated map | Curved lanes and parcel motion, collision-free labels, closure/direction marks, font coverage and motion/sound preferences |
| 9. Correctness and UI QA | Independent reference checks, complete UI flows, save restoration, native rendered screenshots |
| 10. Releases/documentation | Windows/web exports, isolated pack checks, Hungarian guide/developer docs and explicit browser limitation |

Outputs: `export/windows/MisplacedMail.exe` and `export/web/`. Double-click `Play.cmd` for Windows. With Python and a browser available, run `python export/web/server.py` and visit `http://localhost:8080`.

Earlier download-archive cleanup was rejected by automatic approval review (“blocked by policy”); archives outside the workspace remain untouched. A bulk documentation PowerShell write was also rejected; narrower explicit in-workspace patches completed the documentation.

## Graphics refresh — 2026-10-14

The academy, campaign, tree archive and original lab share original vector space artwork, gradient backgrounds, shaded planets, sealed envelopes, rounded controls and themed scrollbars. The academy illustration and topic glyphs are new; selected routes glow, delivery has a short trail, and campaign stages have visible panels. Settings moved below the academy cards. Existing learning models, input areas, map geometry and saved-progress rules are preserved.

- Final `scripts/build.ps1 -Target All`: **40,280 model checks**, **265 lab UI checks**, **8,552 courier UI checks**, **1,185 tree/audio/autoplay UI checks**; **0 failures**, no engine/script errors.
- Final rendered runners, executed sequentially on Intel UHD Graphics 620 / OpenGL 3.3: **270 lab checks**, **8,569 courier checks**, **1,195 tree/audio/autoplay checks**; **0 failures**, empty error logs.
- Inspected screenshots of the academy, academy footer/settings, tier chooser, BFS frontier, varied dense graph, glowing network, Floyd matrix, parcel travel, original lab/report, empty tree, rotations and compact courier/tree views. Additional academy screenshots were inspected at **1280×900** and **1000×700**. Artwork ignores pointer input, and reduced motion pauses the decorative animation.
- Both rebuilt release packs pass **22 isolated checks** each. Windows executable: **115,955,896 bytes**; web PCK: **6,770,344 bytes**; web WASM: **39,514,754 bytes**. The graphics helper scripts and new icon are included; development/QA files remain excluded.
- Standalone Windows executable startup with `--headless --quit-after 20`: exit **0**, no errors. Git diff whitespace check: passed.
- Logs: `qa/graphics-build.log`, `qa/graphics-render-{lab,courier,tree}.log`, separate empty render error logs, and `qa/graphics-release-startup.log`. Rendered captures are under `qa/`.

Web pack validation uses desktop Godot; browser WebAssembly/WebGL gameplay was not retested. Releases remain local, with no remote publication.
