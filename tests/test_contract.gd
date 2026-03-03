extends "res://tests/suite_base.gd"


func run() -> void:
	suite_name = "StepResult Contract (all 9)"
	for script in _GM.ALGORITHM_SCRIPTS:
		var algo = script.new()
		var algo_name: String = algo.get_name()
		var steps: Array = _run_all_steps(algo)
		for i: int in steps.size():
			_check_step(steps[i], i, algo_name)


func _check_step(step: Dictionary, i: int, algo_name: String) -> void:
	var prefix: String = "%s[%d]" % [algo_name, i]
	assert_has_key(step, "state_changes", "%s has state_changes" % prefix)
	assert_has_key(step, "structure",     "%s has structure"     % prefix)
	assert_has_key(step, "message",       "%s has message"       % prefix)
	assert_has_key(step, "is_complete",   "%s has is_complete"   % prefix)

	if step.has("state_changes"):
		var sc: Variant = step["state_changes"]
		assert_true(sc is Array, "%s state_changes is Array" % prefix)
		if sc is Array:
			for change in sc:
				assert_true(change is Dictionary, "%s state_changes entry is Dict" % prefix)
				if change is Dictionary:
					assert_has_key(change, "id",    "%s entry has id"    % prefix)
					assert_has_key(change, "state", "%s entry has state" % prefix)
					if change.has("state"):
						var st: Variant = change["state"]
						assert_true(
							st == "frontier" or st == "visited",
							"%s state is frontier|visited (got '%s')" % [prefix, str(st)]
						)

	if step.has("structure"):
		assert_true(step["structure"] is Array, "%s structure is Array" % prefix)

	if step.has("message"):
		var msg: Variant = step["message"]
		assert_true(msg is String, "%s message is String" % prefix)
		if msg is String:
			assert_true(msg.length() > 0, "%s message is non-empty" % prefix)

	if step.has("is_complete"):
		assert_true(step["is_complete"] is bool, "%s is_complete is bool" % prefix)

	if step.has("examined_edge"):
		var ee: Variant = step["examined_edge"]
		assert_true(ee is Dictionary, "%s examined_edge is Dict" % prefix)
		if ee is Dictionary:
			assert_has_key(ee, "from", "%s examined_edge has from" % prefix)
			assert_has_key(ee, "to",   "%s examined_edge has to"   % prefix)
