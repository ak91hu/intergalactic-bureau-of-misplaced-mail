# Add an algorithm

1. Read PROJECT.md and the StepResult contract. Implement AlgorithmX.gd extending AlgorithmBase; initialize the inherited flag and return a complete result on every step.
2. Add deterministic tests for the final result and noteworthy transitions; register the suite in tests/runner.gd.
3. Append the script to GraphManager.ALGORITHM_SCRIPTS and add an enum entry. Extend LabMenu.CARD_DATA, GameUI references and MissionSession.RULES at the same index. Extend CourierLessons, CourierLevels and CourierSession for campaign learning and execution mechanics.
4. Provide three progressive campaign tiers with real cost consequences, Hungarian formulas/feedback, hints/undo and a learning report. Retain meaningful lab checkpoints separately. Ensure choices fit the displayed graph policy.
5. Extend nine-algorithm loops, persistence validation, daily rotation and next-mission modulo. Check the fixed shortest-path highlighting if the algorithm uses another route.
6. Run scripts/build.ps1 -Godot <engine> -Target Tests and render both UI runners. Preserve both save namespaces and keep lab practice unscored.

Use workflows/3-add-and-export.md to build playable distributions afterward.
