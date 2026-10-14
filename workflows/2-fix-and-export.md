# Fix and export

1. Reproduce with tests/runner.gd, tests/ui_smoke.gd or tests/courier_ui.gd. Identify model/algorithm, decision feedback, snapshots, persistence, scene layout or rendering.
2. Make the smallest appropriate fix. Keep all algorithm indices aligned, preserve signed-vs-absolute lane policies, and deep-copy timeline snapshots.
3. Run scripts/build.ps1 -Godot <Godot 4.7.2 executable> -Target All. It imports, tests, clears the export cache, and produces Web and Windows builds with matching templates.
4. For a layout change, render the relevant UI runner with -- --screenshots and inspect qa/. Check regenerated dense maps, compact layouts, formulas and pinned report actions.
5. Run the exported Windows executable. Serve export/web with its copied server.py and verify browser startup and gameplay where a browser is available. Record any verification that could not be performed.
6. Keep export/, qa/ and .godot/ untracked. Include the font license; larger font-containing packs are expected. Distinguish desktop pack tests from actual browser gameplay. Publish only when requested.
