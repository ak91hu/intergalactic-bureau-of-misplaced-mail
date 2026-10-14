extends SceneTree

var failures: int = 0
var checks: int = 0
var capture: bool = false
var state: Node

func _initialize() -> void:
	capture = "--screenshots" in OS.get_cmdline_user_args()
	_run.call_deferred()

func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("UI FAIL: " + text)

func settle() -> void:
	for frame: int in range(4):
		await process_frame

func screenshot(name: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		var result: Error = root.get_texture().get_image().save_png("res://qa/" + name + ".png")
		check(result == OK, "screenshot saved: " + name)

func _run() -> void:
	state = root.get_node("GameState")
	state.SAVE_PATH = "user://ibmm_lab_ui_test.cfg"
	state.sound_enabled = false
	var old_scores: Dictionary = state.best_scores.duplicate()
	var old_medals: Dictionary = state.medals.duplicate()
	var save_exists: bool = FileAccess.file_exists(state.SAVE_PATH)
	var original_save: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if save_exists else PackedByteArray()
	if capture:
		DirAccess.make_dir_recursive_absolute("res://qa")
	var menu = load("res://MenuScene.tscn").instantiate()
	root.add_child(menu)
	await settle()
	check(menu._grid.get_child_count() == 9, "all nine menu cards exist")
	check(menu._root.size.x > 900 and menu._root.size.y > 600, "menu fills viewport")
	await screenshot("mission-desk")
	menu.queue_free()
	await settle()
	for index: int in range(9):
		state.selected_algorithm = index
		state.practice_mode = false
		var main = load("res://Main.tscn").instantiate()
		root.add_child(main)
		await settle()
		check(main.department_node_map.size() == 6, "six departments present")
		for node: Node2D in main.department_node_map.values():
			var bounds := Rect2(node.global_position - Vector2(92, 36) * node.global_scale, Vector2(184, 72) * node.global_scale)
			check(main._board.encloses(bounds), "department fits board: " + node.department_id)
		var guard: int = 0
		while main.graph_manager.cursor < main.graph_manager.timeline.size() - 1 and guard < 200:
			main.game_ui.request_advance()
			if main.game_ui._blocked:
				check(main.game_ui.advance_button.disabled, "checkpoint blocks advancing")
				check(not main.game_ui._auto_play, "checkpoint pauses auto-play")
				var before: int = main.graph_manager.cursor
				main.game_ui.request_advance()
				check(main.graph_manager.cursor == before, "cannot skip checkpoint")
				main._answer("invalid answer")
				check(main.graph_manager.cursor == before, "invalid answer cannot advance UI")
				if index == 0 and main.mission.answered.is_empty():
					await settle()
					await screenshot("checkpoint")
					main._hint()
				var question: Dictionary = main.mission.pending(main.graph_manager.cursor + 1)
				if index == 0 and main.mission.answered.is_empty():
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT
					click.pressed = true
					click.position = main.department_node_map[question["answer"]].global_position
					main._unhandled_input(click)
					check(main.graph_manager.cursor == before + 1, "direct map selection resolves checkpoint")
				else:
					var key := InputEventKey.new()
					key.pressed = true
					key.keycode = KEY_1 + question["options"].find(question["answer"])
					main.game_ui._unhandled_key_input(key)
					check(main.graph_manager.cursor == before + 1, "number shortcut resolves checkpoint")
			guard += 1
			await process_frame
		check(guard < 200, "mission finishes")
		check(main.mission.answered.size() == 3, "three questions answered in UI")
		check(main.game_ui._complete, "completion shown")
		check(main.game_ui.next_button.visible, "next mission available")
		check(state.medals.has(index), "mission recorded")
		if index == 3:
			await settle()
			await screenshot("report-delivered")
		main._reset()
		check(main.graph_manager.cursor == -1 and main.mission.score == 0, "restart clears scene state")
		main.queue_free()
		await settle()
	state.practice_mode = true
	state.selected_algorithm = 0
	var practice = load("res://Main.tscn").instantiate()
	root.add_child(practice)
	await settle()
	practice.game_ui.request_advance()
	practice.game_ui.request_advance()
	practice.graph_manager.rewind_algorithm()
	check(practice.graph_manager.cursor == 0, "practice back works")
	practice.game_ui.toggle_auto()
	practice.game_ui._process(practice.game_ui._auto_speed)
	check(practice.graph_manager.cursor == 1, "auto-play advances after selected interval")
	practice.game_ui.stop_auto()
	practice.game_ui.toggle_reference()
	check(practice.game_ui.is_reference_open(), "guide opens")
	var before: int = practice.graph_manager.cursor
	practice.game_ui.request_advance()
	check(practice.graph_manager.cursor == before, "guide pauses interaction")
	await settle()
	await screenshot("algorithm-guide")
	practice.game_ui.toggle_reference()
	check(not practice.game_ui.is_reference_open(), "guide closes")
	root.size = Vector2i(1000, 700)
	await settle()
	for node: Node2D in practice.department_node_map.values():
		var bounds := Rect2(node.global_position - Vector2(92, 36) * node.global_scale, Vector2(184, 72) * node.global_scale)
		check(practice._board.encloses(bounds), "small window keeps department visible")
	await screenshot("compact-window")
	practice.queue_free()
	await settle()
	state.best_scores = old_scores
	state.medals = old_medals
	if save_exists:
		var restored := FileAccess.open(state.SAVE_PATH, FileAccess.WRITE)
		restored.store_buffer(original_save)
		restored.close()
	else:
		DirAccess.remove_absolute(state.SAVE_PATH)
	print("UI smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
