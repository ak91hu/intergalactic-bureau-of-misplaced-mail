extends SceneTree

var checks: int = 0
var failures: int = 0
var capture: bool = false

func _initialize() -> void:
	capture = "--screenshots" in OS.get_cmdline_user_args()
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("TREE/AUTO UI FAIL: " + message)

func settle() -> void:
	for frame: int in range(4): await process_frame

func screenshot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://qa/"+name+".png") == OK,"rendered screenshot saved")

func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.SAVE_PATH = "user://ibmm_tree_ui_test.cfg"
	var existed: bool = FileAccess.file_exists(state.SAVE_PATH)
	var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(state.SAVE_PATH) if existed else PackedByteArray()
	var original: Dictionary = {}
	for field: String in ["best_scores","medals","courier_scores","courier_medals","tree_scores","tree_medals","sound_enabled","music_enabled","music_volume","reduced_motion"]:
		var value: Variant = state.get(field)
		original[field] = value.duplicate(true) if value is Dictionary else value
	state.sound_enabled = false
	state.music_enabled = false
	state.reduced_motion = true
	state.music_volume = 0.22
	var audio: Node = root.get_node("BureauAudio")
	check(audio.music.stream.get_length()>60 and audio.music.stream.loop,"real ambient recording loops across scenes")
	for cue: AudioStreamWAV in audio.cues.values():
		check(cue.data.decode_s16(0)==0 and cue.data.decode_s16(cue.data.size()-2)==0,"soft effect starts and ends at zero amplitude")
	check(audio.music.volume_db<=-18,"music playback stays attenuated")
	if capture: DirAccess.make_dir_recursive_absolute("res://qa")
	var menu = load("res://MenuScene.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await settle()
	check(menu._grid.get_child_count()==9 and menu._tree_grid.get_child_count()==3,"academy exposes all 12 topics")
	check(menu.find_child("MusicVolume",true,false) != null,"music slider is accessible")
	var slider: HSlider = menu.find_child("MusicVolume",true,false)
	slider.value = 15
	check(is_equal_approx(state.music_volume,0.15),"music slider changes persistent volume")
	check(menu.guide_card.heading.text.contains("elmentve"),"settings changes confirm successful save")
	await screenshot("academy-v31")
	menu._choose_tree(2)
	await settle()
	check(menu._overlay.is_visible_in_tree(),"red-black three-tier chooser opens")
	await screenshot("tree-tier-picker")
	menu._start_tree(2,0)
	await settle()
	check(current_scene.get_script().resource_path == "res://TreeScene.gd","academy launches the real tree scene")
	current_scene.queue_free()
	current_scene = null
	await settle()
	for kind: int in range(3):
		for tier: int in range(3):
			state.tree_kind = kind
			state.tree_tier = tier
			state.tree_variant = 0
			var scene = load("res://TreeScene.tscn").instantiate()
			root.add_child(scene)
			current_scene = scene
			await settle()
			var before: int = scene.cursor
			scene._choose("not offered")
			check(scene.cursor == before,"invalid tree input cannot advance")
			var wrong: String = "left" if scene.frames[0]["action"] != "left" else "right"
			scene._choose(wrong)
			check(scene.cursor == before and scene.mistakes==1,"wrong tree answer preserves state")
			check(scene.guide_card.heading.text.contains("nem változott"),"wrong answer reassures learner that the tree is unchanged")
			var saw_rotation: bool = false
			for guard: int in range(500):
				if scene.cursor == scene.frames.size()-1: break
				var expected: String = scene.frames[scene.cursor+1]["action"]
				var index: int = scene._options.find(expected)
				check(index>=0,"correct tree action is offered")
				scene.choices.get_child(index).pressed.emit()
				await process_frame
				check(scene.board.frame["nodes"] == scene.frames[scene.cursor]["nodes"],"rendered tree uses the real snapshot")
				if not saw_rotation and expected in ["rotate_left","rotate_right"]:
					saw_rotation = true
					await screenshot("tree-%d-rotation" % kind)
			check(scene.cursor==scene.frames.size()-1,"manual tree lesson completes: %d:%d" % [kind,tier])
			check(state.tree_medals.has("%d:%d" % [kind,tier]),"manual tree lesson saves a medal")
			check(scene.guide_card.message.text.contains("mentettük"),"manual result confirms actual local save")
			if kind == 2 and tier == 0:
				scene._save_error = ERR_CANT_CREATE
				scene._refresh()
				check(scene.retry_save_button.visible and scene.guide_card.heading.text.contains("nem sikerült"),"tree save failure offers recovery and does not claim success")
				scene.retry_save_button.pressed.emit()
				check(not scene.retry_save_button.visible and scene.guide_card.message.text.contains("mentettük"),"retrying tree save restores successful status")
			await settle()
			for point: Vector2 in scene.board.positions.values():
				check(Rect2(Vector2.ZERO,scene.board.size).grow(-10).has_point(point),"tree node fits board")
			if tier == 1: await screenshot("tree-%d-report" % kind)
			scene.queue_free()
			current_scene = null
			await settle()
	# Auto completes every tree tier without changing any personal best.
	var saved_scores: Dictionary = state.tree_scores.duplicate(true)
	for kind: int in range(3):
		for tier: int in range(3):
			state.tree_kind = kind
			state.tree_tier = tier
			var scene = load("res://TreeScene.tscn").instantiate()
			root.add_child(scene)
			await settle()
			scene.auto_button.pressed.emit()
			scene._process(scene.interval*0.5)
			check(scene.cursor == -1,"tree auto honors selected delay")
			scene._process(scene.interval*0.5)
			check(scene.cursor == 0,"tree auto advances when interval elapses")
			scene._guide()
			check(not scene.auto_play,"tree guide pauses autoplay")
			scene._process(10)
			check(scene.cursor==0,"tree guide prevents timer advances")
			scene._close_guide()
			check(scene.guide_card.heading.text.contains("Folytathatod"),"closing guide tells learner how to continue")
			await settle()
			scene._toggle_auto()
			for guard: int in range(500):
				if not scene.auto_play: break
				scene._process(scene.interval)
				await process_frame
			check(scene.cursor==scene.frames.size()-1 and not scene.auto_play,"tree autoplay completes and stops")
			check(state.tree_scores==saved_scores,"tree demonstration never awards scores")
			if kind==2 and tier==2:
				root.size = Vector2i(1000,700)
				await settle()
				check(scene.sidebar.get_rect().end.x<=scene.size.x,"compact tree sidebar fits viewport")
				check(scene.controls.get_combined_minimum_size().x<=scene.size.x-48,"compact playback controls fit viewport")
				check(scene.bottom.get_rect().end.y<=scene.controls.position.y-8,"explanation stays above playback controls")
				await screenshot("tree-compact")
				scene._undo()
				var previous: int = scene.cursor
				scene._hint()
				scene._hint()
				check(scene.hints==1,"repeated tree hint charged once per decision")
				check(scene.cursor==previous,"hint does not advance the tree")
			scene.queue_free()
			await settle()
	root.size = Vector2i(1280,900)
	# A real campaign demo must run all 27 lessons and respect animation/pause locks.
	var courier_scores: Dictionary = state.courier_scores.duplicate(true)
	for algorithm: int in range(9):
		for tier: int in range(3):
			state.courier_algorithm = algorithm
			state.courier_tier = tier
			var scene = load("res://CourierScene.tscn").instantiate()
			root.add_child(scene)
			await settle()
			scene.auto_button.pressed.emit()
			check(scene.auto_play and scene.demonstration,"campaign auto is a visible demonstration")
			var before: int = scene.session.turns
			scene._process(scene.auto_interval/2)
			check(scene.session.turns==before,"campaign auto respects selected speed")
			scene._process(scene.auto_interval/2)
			check(scene.session.turns>before,"campaign timer advances a real decision")
			scene._open_guide(false)
			check(not scene.auto_play,"campaign guide pauses autoplay")
			scene._close_guide()
			await settle()
			scene._toggle_auto()
			for guard: int in range(800):
				if not scene.auto_play: break
				scene._process(scene.auto_interval)
				await process_frame
			check(scene.session.phase=="complete" and not scene.auto_play,"campaign autoplay completes %d:%d" % [algorithm,tier])
			check(state.courier_scores==courier_scores,"campaign demonstration cannot award medals or XP")
			scene.queue_free()
			await settle()
	# Original scored lab resumes auto after each answered checkpoint.
	state.practice_mode = false
	for algorithm: int in range(9):
		state.selected_algorithm = algorithm
		var lab = load("res://Main.tscn").instantiate()
		root.add_child(lab)
		await settle()
		lab.game_ui.play_button.pressed.emit()
		for guard: int in range(400):
			if lab.game_ui._complete: break
			if lab.game_ui._blocked:
				check(not lab.game_ui._auto_play,"scored lab waits for learner answer")
				var guide_text: String = lab.game_ui.guidance_label.text
				check(guide_text.contains("válaszadás után"),"lab explains why autoplay is waiting and when it resumes")
				var pending: Dictionary = lab.mission.pending(lab.graph_manager.cursor+1)
				lab._answer(pending["answer"])
				check(lab.game_ui._auto_play or lab.game_ui._complete,"lab auto resumes after checkpoint answer")
			else: lab.game_ui._process(lab.game_ui._auto_speed)
			await process_frame
		check(lab.game_ui._complete,"lab autoplay reaches final report: %d" % algorithm)
		lab.queue_free()
		await settle()
	for field: String in original: state.set(field,original[field])
	if existed:
		var save := FileAccess.open(state.SAVE_PATH,FileAccess.WRITE)
		save.store_buffer(original_bytes)
		save.close()
	else: DirAccess.remove_absolute(state.SAVE_PATH)
	print("Tree/audio/auto UI: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
