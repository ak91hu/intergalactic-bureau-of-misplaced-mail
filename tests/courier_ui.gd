extends SceneTree

var checks: int = 0
var failures: int = 0
var capture: bool = false
var state: Node

func _initialize() -> void:
	capture = "--screenshots" in OS.get_cmdline_user_args()
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("COURIER UI FAIL: " + message)

func settle(frames: int = 3) -> void:
	for index: int in frames: await process_frame

func screenshot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://qa/courier-" + name + ".png") == OK, "rendered screenshot saved")

func check_map(board: Node) -> void:
	var occupied: Array = []
	for edge: Dictionary in board.session.graph.edges:
		var rect: Rect2 = board._geometry(edge)["label_rect"]
		check(Rect2(0,62,board.size.x,board.size.y-104).encloses(rect), "edge label stays inside map: " + edge["key"])
		for node: Dictionary in board.session.graph.nodes:
			var center: Vector2 = board.node_point(node["id"])
			check(not rect.intersects(Rect2(center-Vector2(35,35),Vector2(70,70))), "edge label avoids station: " + edge["key"] + "/" + node["id"])
			check(not rect.intersects(Rect2(center+Vector2(-76,35),Vector2(152,25))), "edge label avoids station caption: %s/%s rect=%s center=%s size=%s variant=%d" % [edge["key"],node["id"],rect,center,board.size,board.session.level["variant"]])
		for other: Rect2 in occupied:
			check(not rect.grow(3).intersects(other), "edge labels do not overlap")
		occupied.append(rect)

func _run() -> void:
	state = root.get_node("GameState")
	state.SAVE_PATH = "user://ibmm_courier_ui_test.cfg"
	var ui_theme = load("res://BureauTheme.gd")
	for character: int in [0x0151,0x0171,0x00e1,0x00e9,0x221e,0x2192,0x2264,0x00d7]:
		check(ui_theme.UI_FONT.has_char(character), "bundled font covers Hungarian and teaching symbols")
	var script = load("res://CourierScene.gd")
	if script == null or not script.can_instantiate():
		check(false, "CourierScene must compile")
		quit(1)
		return
	var original: Dictionary = {}
	for field: String in ["best_scores", "medals", "courier_scores", "courier_medals"]:
		original[field] = state.get(field).duplicate(true)
	var existed: bool = FileAccess.file_exists(state.SAVE_PATH)
	var save_bytes: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if existed else PackedByteArray()
	state.sound_enabled = false
	state.reduced_motion = true
	if capture: DirAccess.make_dir_recursive_absolute("res://qa")
	var menu = load("res://MenuScene.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await settle()
	check(menu._grid.get_child_count() == 9, "all learning topics available")
	await screenshot("academy")
	menu._choose_tier(3)
	await settle()
	check(menu._overlay.is_visible_in_tree(), "three-tier lesson picker opens")
	await screenshot("lesson-picker")
	menu._start_courier(3, 0)
	await settle(5)
	check(current_scene != null and current_scene.get_script().resource_path == "res://CourierScene.gd", "menu navigates to real courier scene")
	check(current_scene.session.algorithm() == 3, "selected lesson reaches scene")
	var original_edges: Array = current_scene.session.graph.edges.duplicate(true)
	current_scene._fresh()
	await settle(5)
	check(current_scene.session.level["variant"] == 1 and current_scene.session.graph.edges != original_edges, "new-network action reloads a genuinely varied map")
	current_scene._next()
	await settle(5)
	check(current_scene.session.level["tier"] == 1 and current_scene.session.level["variant"] == 0, "next lesson moves to the next learning tier")
	current_scene._home()
	await settle(5)
	check(current_scene.get_script().resource_path == "res://MenuScene.gd", "home returns to academy")
	current_scene.queue_free()
	current_scene = null
	await settle()
	for algorithm: int in range(9):
		for tier: int in range(3):
			state.courier_algorithm = algorithm
			state.courier_tier = tier
			state.courier_variant = 0
			var scene = load("res://CourierScene.tscn").instantiate()
			root.add_child(scene)
			current_scene = scene
			await settle()
			check(scene._choice_ids == ["begin"], "briefing has clear start action")
			for node: Dictionary in scene.session.graph.nodes:
				var point: Vector2 = scene.board.node_point(node["id"])
				check(Rect2(0,0,scene.board.size.x,scene.board.size.y).encloses(Rect2(point - Vector2(76,44), Vector2(152,118))), "station and label stay on board")
			check(scene.code_panel.get_rect().end.y < scene.footer.position.y, "pseudocode does not overlap controls")
			check_map(scene.board)
			if algorithm == 0 and tier == 0: await screenshot("briefing")
			var guard: int = 0
			while scene.session.phase != "complete" and guard < 160:
				var expected: Array = scene.session.expected_choices()
				check(not expected.is_empty(), "visible mission has a correct continuation")
				if expected.is_empty(): break
				var choice: String = expected.front()
				var before: int = scene.session.turns
				if algorithm == 0 and tier == 0 and scene.session.phase == "search" and scene.session.frontier.size() == 2:
					await screenshot("frontier")
					var click := InputEventMouseButton.new()
					click.pressed = true
					click.button_index = MOUSE_BUTTON_LEFT
					click.position = scene.board.node_point(choice.trim_prefix("node:"))
					scene.board._gui_input(click)
				elif scene.session.phase == "matrix" and algorithm == 7 and tier == 2:
					if scene.session.relays.size() == 2: await screenshot("matrix")
					var ids: Array = scene.session.graph.ids()
					var cell_x: float = minf(58,(scene.board.size.x-110)/ids.size())
					var click := InputEventMouseButton.new()
					click.pressed = true
					click.button_index = MOUSE_BUTTON_LEFT
					click.position = Vector2((scene.board.size.x-cell_x*ids.size())/2 + cell_x*(ids.find(choice.trim_prefix("node:"))+0.5),90)
					scene.board._gui_input(click)
				elif scene.session.phase == "network" and algorithm == 5 and tier == 2:
					var edge: Dictionary = scene.session.graph.edge_by_key(choice.trim_prefix("edge:"))
					var click := InputEventMouseButton.new()
					click.pressed = true
					click.button_index = MOUSE_BUTTON_LEFT
					click.position = scene.board._geometry(edge)["mid"]
					scene.board._gui_input(click)
				else:
					var selected_index: int = scene._choice_ids.find(choice)
					check(selected_index >= 0, "correct action has a real UI button")
					if selected_index < 0: break
					var button: Button = scene.action_grid.get_child(selected_index)
					button.pressed.emit()
				check(scene.session.turns == before + 1, "one decision: algo=%d tier=%d phase=%s choice=%s busy=%s status=%s" % [algorithm,tier,scene.session.phase,choice,scene._busy,scene.session.status])
				if scene.session.turns != before + 1: break
				await process_frame
				if algorithm == 3 and tier == 0 and scene.session.phase == "edge_check" and scene.session.current == "C": await screenshot("relaxation")
				if scene.session.phase == "ready" and algorithm == 6 and tier == 2: await screenshot("route-plan")
				guard += 1
			check(guard < 160 and scene.session.phase == "complete", "each of 27 missions completes through the UI")
			check(scene.completion_controls.visible, "report has pinned next/replay buttons")
			check(scene.completion_controls.get_child_count() == 2, "clear follow-up actions available")
			check(scene.sidebar.get_global_rect().encloses(scene.completion_controls.get_global_rect()), "report actions remain inside the sidebar")
			check(state.courier_medals.has("%d:%d" % [algorithm,tier]), "completed lesson saved")
			check(scene.feedback_label.text.contains("AMIT MEGTANULTÁL"), "completion states learning takeaway")
			check(scene.guide_card.message.text.contains("mentettük"),"report confirms successful local save")
			if algorithm == 0 and tier == 0:
				scene._save_error = ERR_CANT_CREATE
				scene._refresh()
				check(scene.guide_card.heading.text.contains("nem sikerült") and scene.completion_controls.get_child_count()==3,"campaign save failure offers retry without claiming success")
				scene._retry_save()
				check(scene.guide_card.message.text.contains("mentettük") and scene.completion_controls.get_child_count()==2,"campaign save retry restores report state")
			if algorithm == 7 and tier == 2: await screenshot("two-parcels-report")
			if algorithm == 5 and tier == 1: await screenshot("network")
			scene.queue_free()
			current_scene = null
			await settle()
	# Layouts also remain readable on regenerated, vertically mirrored maps.
	state.courier_algorithm = 6
	state.courier_tier = 2
	for variant: int in [1,2]:
		state.courier_variant = variant
		var layout_scene = load("res://CourierScene.tscn").instantiate()
		root.add_child(layout_scene)
		await settle()
		check_map(layout_scene.board)
		if variant == 1: await screenshot("varied-map")
		layout_scene.queue_free()
		await settle()
	state.courier_variant = 0
	# Recoverable mistakes and guide/shortcut behavior.
	state.courier_algorithm = 0
	state.courier_tier = 0
	var scene = load("res://CourierScene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	scene._select("begin")
	scene._select("node:A")
	var before: int = scene.session.turns
	scene._select("node:C")
	check(scene.session.turns == before and scene.session.mistakes == 1, "wrong queue choice explained without corrupting state")
	check(scene.feedback_label.text.contains("sor"), "queue mistake visible in feedback")
	check(scene.guide_card.heading.text.contains("állapotod megmaradt"),"queue mistake explicitly says progress is unchanged")
	scene._hint()
	check(scene.session.hints == 1, "help available in UI")
	scene._open_guide(false)
	await settle()
	check(scene._popup_open(), "why guide opens")
	scene._select("node:B")
	check(scene.session.turns == before, "guide blocks background gameplay")
	await screenshot("why-guide")
	scene._close_guide()
	await settle()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1 + scene._choice_ids.find("node:B")
	scene._unhandled_key_input(key)
	check(scene.session.turns == before + 1, "number shortcut chooses the intended station")
	scene._undo()
	check(scene.session.turns == before, "undo restores prior algorithm state")
	scene.queue_free()
	current_scene = null
	await settle()
	# A real animated parcel has input locking and a completion signal.
	state.courier_algorithm = 3
	state.courier_tier = 2
	state.reduced_motion = false
	scene = load("res://CourierScene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	for guard: int in range(120):
		if scene.session.phase == "delivery": break
		scene._select(scene.session.expected_choices().front())
		await process_frame
	var step: String = scene.session.expected_choices().front()
	scene._select(step)
	check(scene._busy, "parcel motion locks duplicate actions")
	check(scene.guide_card.heading.text.contains("úton van"),"moving parcel explains why input is waiting")
	before = scene.session.turns
	scene._select(scene.session.expected_choices().front())
	check(scene.session.turns == before, "in-flight input cannot double-spend route cost")
	await create_timer(0.13).timeout
	check(scene.board._travel_progress > 0 and scene.board._travel_progress < 1, "parcel progresses along actual chosen lane")
	await screenshot("parcel-in-flight")
	await create_timer(0.5).timeout
	check(not scene._busy, "input unlocks after parcel arrival")
	check(scene.guide_card.heading.text.contains("megérkezett"),"arrival announces that learner can continue")
	# Replan and expose the real budget consequence through the UI.
	scene._undo()
	# The expensive shortcut is a curved lane, so the parcel must follow its arc.
	scene._select("node:D")
	check(scene._busy, "curved shortcut starts an actual delivery")
	var from_point: Vector2 = scene.board.node_point("A")
	var to_point: Vector2 = scene.board.node_point("D")
	check(scene.board.travel_point(0).is_equal_approx(from_point) and scene.board.travel_point(1).is_equal_approx(to_point), "curved parcel motion has exact station endpoints")
	check(scene.board.travel_point(0.5).distance_to(from_point.lerp(to_point,0.5))>30, "parcel follows the drawn curve instead of crossing another station")
	await create_timer(0.25).timeout
	await screenshot("curved-parcel")
	await create_timer(0.4).timeout
	scene._undo()
	state.reduced_motion = true
	scene.board.reduced_motion = true
	scene._select("node:D")
	scene._select("node:H")
	check(scene.session.phase == "failed", "expensive route visibly fails the mission budget")
	check(scene.guide_card.next_action.text.contains("Visszalépés"),"failed route offers an explicit recovery action")
	await screenshot("budget-recovery")
	scene._undo()
	check(scene.session.phase == "delivery", "failed delivery can be repaired")
	root.size = Vector2i(1000,700)
	await settle()
	check(scene.sidebar.get_rect().end.x <= scene.size.x, "compact sidebar stays within viewport")
	check_map(scene.board)
	await screenshot("compact")
	scene.queue_free()
	current_scene = null
	await settle()
	for field: String in original: state.set(field, original[field])
	if existed:
		var save := FileAccess.open(state.SAVE_PATH, FileAccess.WRITE)
		save.store_buffer(save_bytes)
		save.close()
	else:
		DirAccess.remove_absolute(state.SAVE_PATH)
	print("Courier UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

