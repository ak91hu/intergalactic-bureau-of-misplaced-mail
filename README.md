# The Intergalactic Bureau of Misplaced Mail

A Godot educational game about nine graph algorithms, disguised as a dysfunctional space post office. **Version 3 adds a Hungarian courier academy with 27 learning missions:** work the algorithm yourself, choose the actual delivery route or network connections, and compare your cost with the optimum.

**Version 3.1 adds BST, AVL and red-black trees: 12 topics and 36 academy lessons in total.** Tree missions teach insertion, individual comparisons, both rotations, color repairs, search and inorder traversal. Quiet ambient music and soft button sounds have independent controls; music volume saves locally. Campaign and tree autoplay show complete unscored demonstrations at three speeds. Original lab autoplay pauses for checkpoint answers and resumes afterwards.

**Version 3.2 adds a Hungarian dispatcher guide throughout the app.** It explains the current task, the next action, recoverable mistakes, parcel travel, autoplay/pause and saved results. Audio/motion changes acknowledge their saved state. Failed result saves offer a retry instead of claiming success. Tree questions and answers stay ahead of optional technical details.

The refreshed graphics give the academy an original animated space-mail illustration, illustrated topic cards and a gradient starfield. Map stations and tree nodes have shaded planetary surfaces; selected routes glow, and envelopes leave a short trail during delivery. Rounded controls, themed scrollbars and clearer stage indicators keep the interface consistent. Sound and motion settings are below the academy's topic cards; reduced motion stops the decorative animation too. All artwork is rendered locally from vector drawing code.

**Tanulj algoritmust. Tervezz. Kézbesíts.** A magyar futárküldetésekben a saját döntésed változtatja az útvonalat, a költséget és a küldetés eredményét. Látható adatstruktúrák, képletek, pszeudokód és magyarázatok segítik a tanulást.

## Play

- **Windows:** double-click `Play.cmd`, or run `export/windows/MisplacedMail.exe`. The exported game needs no Godot installation.
- **Godot editor:** use **Godot 4.7.2 stable**, open `project.godot`, and press F5.
- **Browser:** after building, run `python export/web/server.py` and open `http://localhost:8080`. Serve over HTTP instead of opening `index.html` as a file.

There are no external game libraries, addons or package-manager dependencies. The engine and export templates are pinned to [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/), the current stable 4.x release as checked on 2026-10-14. GitHub Actions use checkout 7.0.1 and upload-artifact 7.0.2, pinned to commit hashes. Inter is bundled locally with its SIL Open Font License for Hungarian text and mathematical symbols.

## Courier academy / Futárakadémia

- Three progressive tiers for every algorithm: 6–8 stations, varied costs, recipients, optional connections and closed lanes. Generate a new reproducible map with “Új hálózat”.
- Real route choices after planning; costs can cause budget failure or a dead end. Prim/Kruskal build the actual selected network; topological sort executes a legal prerequisite order.
- Visible FIFO/LIFO, predecessor table, relaxation arithmetic, A* g/h/f, components and a clickable all-pairs matrix. Highlighted pseudocode, Hungarian feedback, a complete guide and a step journal explain decisions.
- Reports compare actual cost with the optimum and state the learning takeaway. DFS explicitly does not promise a shortest route. Advanced Floyd–Warshall uses two separate senders.
- Hints, undo and replan; no timer or locked lessons. Local medals, best-score XP, suggested next lesson and a daily map variant.
- A readable space-postal map, curved lanes, collision-aware labels, actual parcel travel, keyboard choices, optional sound and reduced motion.

The **Algoritmuslabor** button retains the previous visualizer, checkpoint missions, practice and old progress. Its original English narration remains available.

## Original lab features

- Nine missions with three decisions each. Traversal, ordering, Dijkstra, Prim and A* ask about the next processed department; Kruskal asks about the next connection; Bellman-Ford and Floyd-Warshall ask about relaxation and route costs.
- Shuffled answer positions, direct department selection on the map, streak bonuses, hints and feedback after mistakes. No timers or locked missions.
- Bronze for finishing, silver for at least two correct answers, gold for three correct without hints. Perfect score: **425 points**. Each hint reduces a correct answer's score by 25 points once.
- Best scores, medals, sound and reduced-motion settings save locally. Total XP is the sum of personal bests, so repeated runs cannot inflate it.
- A suggested next mission and a daily assignment (UTC day, rotating through the same nine missions).
- Practice mode with rewind, three auto-play speeds, restart and an in-game algorithm guide.
- A map fitted to the available space, persistent route/tree highlighting on completion, zoom, pan and a fit-map shortcut.
- Larger text, clear keyboard focus, descriptive node states, optional sound cues and reduced motion.
- Reproducible Windows and single-threaded web exports, plus automated algorithm, gameplay, persistence and UI tests.

## Courier controls

| Action | Control |
| --- | --- |
| Choose | Button, station/edge click, or 1–9 |
| Single offered action | Enter / Space |
| Undo | Z / Backspace |
| Hint | H |
| Explain algorithm / journal | I / L |
| Floyd matrix / map | M |
| Academy / close guide | Esc |

See [GAME_GUIDE.md](GAME_GUIDE.md) for the Hungarian player guide, tier rules and grading.

## Original lab controls

| Action | Control |
| --- | --- |
| Next dispatch | Space or button |
| Choose an answer | 1 / 2 / 3, answer button, or highlighted department |
| Request hint | H |
| Auto / pause | A |
| Restart mission | R |
| Rewind in practice | Left or Back |
| Algorithm guide | I |
| Fit graph | F |
| Zoom / pan | Mouse wheel / middle-button drag |
| Mission desk / close guide | Esc |

Choose `Mode: missions` or `Mode: practice` on the desk before opening an algorithm.

## Build and test

Install Godot **4.7.2 stable** and its matching standard export templates. PowerShell 7 works on Windows and Linux:

```powershell
./scripts/build.ps1 -Godot 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
./scripts/build.ps1 -Godot '/path/to/godot' -Target Tests
./scripts/build.ps1 -Godot '/path/to/godot' -Target Web
```

Alternatively set `GODOT_EXECUTABLE`, or put `godot` / `godot4` on PATH. The script imports resources, runs all four source test entry points, clears the checked in-project scene export cache, exports the selected targets and verifies each pack in isolation. It stops on runtime errors as well as nonzero exit codes. Outputs under `export/` are intentionally untracked.

```text
godot --headless --path . --script res://tests/runner.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/courier_ui.gd
godot --headless --path . --script res://tests/tree_ui.gd
```

For rendered QA, run each UI runner without `--headless` and append `-- --screenshots`. Screenshots appear under `qa/`. The campaign runner plays all 27 lessons and checks map/edge/matrix input, navigation, labels, guides, recovery and animated delivery. The lab runner covers all nine original missions. The tree runner plays all nine tree lessons manually and automatically, all 27 campaign demos, and lab auto/checkpoint resume flows. UI runners select separate test save files before making changes, so an interrupted test cannot write to the player's progress file; run them sequentially.

## Original lab lane rules

The graph has six departments and seven directed edges. **Forms -> Lost has weight -2.**

- Bellman-Ford and Floyd-Warshall use original signed costs: HQ -> Forms -> Lost -> Delivery costs **3 - 2 + 4 = 5**.
- Dijkstra and A* demonstrate nonnegative costs by using absolute weights: the same route costs **3 + 2 + 4 = 9**. Both results are correct for their displayed lane policies.
- Prim and Kruskal demonstrate an undirected graph with absolute weights. Both find a tree with total cost **11**.
- BFS and DFS ignore weights when choosing their traversal.

Campaign maps use their generated displayed costs, closures and reconstructed routes. See [PROJECT.md](PROJECT.md) for architecture, [THIRD_PARTY.md](THIRD_PARTY.md) for assets, and [VALIDATION.md](VALIDATION.md) for current verification and limitations. Source is maintained in the [GitHub repository](https://github.com/ak91hu/intergalactic-bureau-of-misplaced-mail); the verification workflow exports Windows and web packages as downloadable build artifacts.
