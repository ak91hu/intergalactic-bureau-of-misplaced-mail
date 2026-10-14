extends "res://tests/suite_base.gd"

func run() -> void:
	suite_name = "BST / AVL / red-black invariants"
	var cases: Array = [[30,20,10],[10,20,30],[30,10,20],[10,30,20],[41,38,31,12,19,8],[7,3,18,10,22,8,11,26,2,6,13],[10,10,5,15]]
	for tier: int in range(3):
		for variant: int in range(6): cases.append(TreeAlgorithms.sequence(tier,variant))
	var ascending: Array = []
	for key: int in range(1,25): ascending.append(key)
	cases.append(ascending)
	var descending: Array = ascending.duplicate()
	descending.reverse()
	cases.append(descending)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91731
	for variant: int in range(60):
		var data: Array = []
		for key: int in range(1,19): data.append(key)
		for index: int in range(data.size()-1,0,-1):
			var other: int = rng.randi_range(0,index)
			var temp: int = data[index]
			data[index] = data[other]
			data[other] = temp
		cases.append(data)
	for kind: int in range(3):
		var saw_left: bool = false
		var saw_right: bool = false
		var saw_recolor: bool = false
		for data: Array in cases:
			var model := TreeAlgorithms.new()
			var frames: Array = model.build(kind,data,99)
			assert_true(frames.size() > data.size(),"stepwise trace contains comparisons and repairs")
			var expected: Array = []
			for value: int in data:
				if value not in expected: expected.append(value)
			expected.sort()
			var previous_order: Array = []
			for frame: Dictionary in frames:
				var order: Array = []
				var seen: Dictionary = {}
				var state: Dictionary = _walk(frame["nodes"],frame["root"],-1,-100000,100000,seen,order)
				assert_true(state["bst"] and seen.size() == frame["nodes"].size(),"every frame preserves BST order, connectivity and parents")
				if frame["action"] in ["rotate_left","rotate_right"]: assert_eq(order,previous_order,"rotation preserves inorder keys")
				previous_order = order
				saw_left = saw_left or frame["action"] == "rotate_left"
				saw_right = saw_right or frame["action"] == "rotate_right"
				saw_recolor = saw_recolor or frame["action"] == "recolor"
				if frame["stable"]:
					if kind == 1: assert_true(state["avl"],"completed AVL insertion has balance at every node")
					if kind == 2:
						assert_false(frame["nodes"][frame["root"]]["red"],"red-black root is black")
						assert_true(state["rb"],"red-black stable state has no red pairs and equal NIL black heights")
			assert_eq(model.inorder(),expected,"all unique input keys remain sorted")
			assert_eq(frames[-2]["action"],"missing","absent key terminates at NIL")
			if kind != 0: assert_true(model.height(model.root_key) <= 2*log(expected.size()+1)/log(2),"balanced height satisfies logarithmic bound")
			var snapshot: Dictionary = frames.back().duplicate(true)
			model.build(kind,[5,2,8],2)
			assert_eq(frames.back(),snapshot,"trace snapshots survive model reuse")
		if kind != 0:
			assert_true(saw_left and saw_right,"both rotation directions exercised")
		if kind == 2: assert_true(saw_recolor,"red-uncle and line recoloring exercised")
	var found := TreeAlgorithms.new()
	var trace: Array = found.build(2,[30,20,10],20)
	assert_eq(trace[-2]["action"],"found","existing key search finds actual key")
	assert_eq(found.root_key,20,"three descending red-black insertions promote median")
	var avl := TreeAlgorithms.new()
	avl.build(1,[30,10,20],10)
	assert_eq(avl.root_key,20,"AVL left-right repair promotes median")
	assert_eq(avl.rotations,2,"AVL triangle uses two rotations")

func _walk(nodes: Dictionary, key: int, parent: int, lower: int, upper: int, seen: Dictionary, order: Array) -> Dictionary:
	if key == -1: return {"bst":true,"avl":true,"rb":true,"height":0,"black":1}
	if not nodes.has(key) or seen.has(key): return {"bst":false,"avl":false,"rb":false,"height":0,"black":0}
	seen[key] = true
	var node: Dictionary = nodes[key]
	var left: Dictionary = _walk(nodes,node["left"],key,lower,key,seen,order)
	order.append(key)
	var right: Dictionary = _walk(nodes,node["right"],key,key,upper,seen,order)
	var red_pair: bool = false
	for child: int in [node["left"],node["right"]]:
		if node["red"] and child != -1 and nodes[child]["red"]: red_pair = true
	return {
		"bst":left["bst"] and right["bst"] and key > lower and key < upper and node["parent"] == parent,
		"avl":left["avl"] and right["avl"] and absi(left["height"]-right["height"])<=1,
		"rb":left["rb"] and right["rb"] and not red_pair and left["black"]==right["black"],
		"height":1+maxi(left["height"],right["height"]),
		"black":left["black"]+(0 if node["red"] else 1)
	}
