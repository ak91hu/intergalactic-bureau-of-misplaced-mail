# Add and export end to end

Follow workflows/1-add-algorithm.md, then workflows/2-fix-and-export.md. Use current PROJECT.md instead of contributor-specific engine paths in historic examples.

Required outputs: independent correctness tests, three progressive campaign tiers with real consequences, accurate Hungarian feedback/pseudocode, deep snapshots, accessible cards/reports, and release exports built with Godot 4.7.2 stable. Preserve the original lab and both save namespaces.

Run scripts/build.ps1 -Godot <engine path> from the repository. Recheck generated game packs after code changes; a source change alone does not update an existing browser build.
