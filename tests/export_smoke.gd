extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("EXPORT FAIL: " + description)

func _run() -> void:
	check(not OS.get_cmdline_args().has("--editor"), "release pack loaded without editor")
	check(ProjectSettings.get_setting("application/config/version") == "3.2.0", "pack contains current product version")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://MenuScene.tscn", "correct academy main scene key")
	check(root.has_node("GameState"), "pack autoload is present")
	check(root.has_node("BureauAudio"),"persistent audio service is packed")
	check(ResourceLoader.exists("res://assets/FloatingCities.mp3"),"ambient soundtrack is packed")
	check(FileAccess.file_exists("res://assets/MUSIC-LICENSE.txt"),"music attribution included")
	check(FileAccess.file_exists("res://assets/OFL-Inter.txt"), "font license included")
	check(FileAccess.file_exists("res://assets/LICENSE-Godot.txt"), "engine license included")
	check(FileAccess.file_exists("res://assets/COPYRIGHT-Godot.txt"), "engine dependency notices included")
	for path: String in ["res://README.md", "res://tests/runner.gd", "res://tests/courier_ui.gd", "res://scripts/build.ps1", "res://qa/courier-academy.png"]:
		check(not FileAccess.file_exists(path) and not ResourceLoader.exists(path), "development resource excluded: " + path)
	var main = load("res://MenuScene.tscn").instantiate()
	root.add_child(main)
	await process_frame
	check(main._grid.get_child_count() == 9, "packed academy has all nine learning topics")
	check(main._tree_grid.get_child_count() == 3,"packed academy has BST, AVL and red-black lessons")
	check(not main.guide_card.next_action.text.is_empty(),"packed academy offers a clear next action")
	main.queue_free()
	await process_frame
	for path: String in ["res://CourierScene.tscn", "res://LabMenu.tscn", "res://Main.tscn", "res://TreeScene.tscn"]:
		var scene = load(path).instantiate()
		root.add_child(scene)
		await process_frame
		check(scene.is_inside_tree(), "packed campaign/lab scene works: " + path)
		scene.queue_free()
		await process_frame
	print("Release pack: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
