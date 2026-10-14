extends "res://tests/suite_base.gd"

func run() -> void:
	suite_name = "Timeline and mission gameplay"
	for index: int in range(9):
		var manager := GraphManager.new()
		manager.set_algorithm(index)
		assert_true(manager.timeline.size() > 3, "algorithm %d has a timeline" % index)
		assert_eq(manager.cursor, -1, "timeline starts before initialization")
		assert_true(manager.timeline.back()["is_complete"], "timeline reaches completion")
		var mission := MissionSession.new()
		mission.setup(index, manager.timeline)
		assert_eq(mission.questions.size(), 3, "algorithm %d offers three checkpoints" % index)
		for step: int in mission.questions:
			var question: Dictionary = mission.pending(step)
			assert_true(step > 0 and step < manager.timeline.size(), "checkpoint fits timeline")
			assert_eq(question["options"].size(), 3, "three answer choices")
			assert_true(question["answer"] in question["options"], "correct answer selectable")
			var result: Dictionary = mission.answer(step, question["answer"])
			assert_true(result["correct"], "correct choice recognized")
			assert_true(mission.answer(step, question["answer"]).is_empty(), "duplicate submission ignored")
		assert_eq(mission.score, 425, "perfect streak scores 425")
		assert_eq(mission.stars(), 3, "perfect mission earns gold")
		manager.advance_algorithm()
		manager.advance_algorithm()
		manager.rewind_algorithm()
		assert_eq(manager.cursor, 0, "practice rewind restores earlier step")
		assert_eq(manager.timeline[0]["states"][START], "frontier" if index not in [7, 8] else "default", "snapshot is independent of future states")
		manager.reset_algorithm()
		assert_eq(manager.cursor, -1, "restart resets cursor")
		mission.setup(index, manager.timeline)
		assert_eq(mission.score, 0, "restart resets score")
		var first: int = mission.questions.keys()[0]
		mission.use_hint(first)
		mission.use_hint(first)
		mission.answer(first, mission.questions[first]["answer"])
		assert_eq(mission.score, 100, "repeated hints charge only once")
		for step: int in mission.questions:
			if step != first:
				mission.answer(step, mission.questions[step]["answer"])
		assert_eq(mission.stars(), 2, "hinted perfect run earns silver")
		mission.setup(index, manager.timeline)
		first = mission.questions.keys()[0]
		assert_true(mission.answer(first, "invalid answer").is_empty(), "invalid answers cannot resolve a checkpoint")
		for step: int in mission.questions:
			var question: Dictionary = mission.questions[step]
			for choice: String in question["options"]:
				if choice != question["answer"]:
					mission.answer(step, choice)
					break
		assert_eq(mission.score, 0, "wrong answers earn no points")
		assert_eq(mission.stars(), 1, "completing with mistakes still earns bronze")
		manager.free()
