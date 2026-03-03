class_name TestSuite
extends RefCounted

const _GM = preload("res://GraphManager.gd")

var GRAPH: Dictionary = _GM.DEPARTMENTS
var START: String = _GM.START_NODE

var suite_name: String = "Unnamed"
var pass_count: int = 0
var fail_count: int = 0


func run() -> void:
	pass


func assert_eq(actual: Variant, expected: Variant, desc: String) -> void:
	if actual == expected:
		pass_count += 1
	else:
		fail_count += 1
		printerr("  FAIL: %s\n    expected: %s\n    got:      %s" % [desc, str(expected), str(actual)])


func assert_true(cond: bool, desc: String) -> void:
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		printerr("  FAIL: %s — expected true" % desc)


func assert_false(cond: bool, desc: String) -> void:
	if not cond:
		pass_count += 1
	else:
		fail_count += 1
		printerr("  FAIL: %s — expected false" % desc)


func assert_has_key(d: Dictionary, key: Variant, desc: String) -> void:
	if d.has(key):
		pass_count += 1
	else:
		fail_count += 1
		printerr("  FAIL: %s — missing key '%s'" % [desc, str(key)])


func assert_in_range(val: float, lo: float, hi: float, desc: String) -> void:
	if val >= lo and val <= hi:
		pass_count += 1
	else:
		fail_count += 1
		printerr("  FAIL: %s — %f not in [%f, %f]" % [desc, val, lo, hi])


# Drive algorithm from initialize() through all advance() calls until is_complete.
# Returns Array of all StepResult dicts in order (index 0 = initialize result).
func _run_all_steps(algo) -> Array:
	var steps: Array = []
	var r: Dictionary = algo.initialize(GRAPH, START)
	steps.append(r)
	var guard: int = 0
	while not r.get("is_complete", false):
		r = algo.advance(GRAPH)
		steps.append(r)
		guard += 1
		if guard > 2000:
			push_error("GUARD: algorithm did not complete in 2000 steps")
			break
	return steps
