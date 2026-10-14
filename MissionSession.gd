class_name MissionSession
extends RefCounted

const RULES: Array[String] = [
	"A queue is first in, first out. Choose the oldest waiting department.",
	"A stack is last in, first out. Choose the most recently added department.",
	"Only departments with no unfinished incoming dependencies are ready.",
	"Choose the unfinished department with the smallest total cost from HQ.",
	"Relax an edge when start distance + edge cost improves its destination.",
	"Choose the cheapest connection from the growing tree to a new department.",
	"Choose the smallest f = g + h, using actual cost plus estimated remaining cost.",
	"Try each department as a relay: d(i,j) = min(d(i,j), d(i,k) + d(k,j)).",
	"Choose the cheapest remaining edge that does not join an existing component to itself."
]
var questions: Dictionary = {}
var answered: Dictionary = {}
var hinted: Dictionary = {}
var score: int = 0
var correct_count: int = 0
var streak: int = 0
var algorithm: int = 0

func setup(index: int, timeline: Array) -> void:
	algorithm = index
	questions.clear()
	answered.clear()
	hinted.clear()
	score = 0
	correct_count = 0
	streak = 0
	var candidates: Array = []
	if index not in [4, 7]:
		for step: int in range(1, timeline.size()):
			var frame: Dictionary = timeline[step]
			if index == 8 and frame.has("examined_edge"):
				var edge: Dictionary = frame["examined_edge"]
				candidates.append({"step": step, "answer": edge["from"] + "|" + edge["to"], "edge": true})
			elif index != 8:
				for change: Dictionary in frame["state_changes"]:
					if change["state"] == "visited" and change["id"] != GraphManager.START_NODE:
						candidates.append({"step": step, "answer": change["id"], "edge": false})
	if candidates.size() >= 3:
		for number: int in range(3):
			var candidate: Dictionary = candidates[int(round(number * (candidates.size() - 1) / 2.0))]
			var options: Array = []
			if candidate["edge"]:
				for from_id: String in GraphManager.DEPARTMENTS:
					for to_id: String in GraphManager.DEPARTMENTS[from_id]["neighbors"]:
						options.append(from_id + "|" + to_id)
			else:
				options = GraphManager.DEPARTMENTS.keys()
			options.erase(candidate["answer"])
			options.shuffle()
			options = options.slice(0, 2)
			options.append(candidate["answer"])
			options.shuffle()
			questions[candidate["step"]] = {
				"prompt": "Which connection is examined next?" if candidate["edge"] else "Which department is processed next?",
				"answer": candidate["answer"], "options": options,
				"hint": RULES[index], "node_choice": not candidate["edge"]
			}
	else:
		var bank: Array = _concept_questions(index)
		for number: int in range(3):
			var step: int = maxi(1, int((number + 1) * (timeline.size() - 1) / 4.0))
			questions[step] = bank[number]

func pending(step: int) -> Dictionary:
	return questions.get(step, {}) if not answered.has(step) else {}

func answer(step: int, choice: String) -> Dictionary:
	var question: Dictionary = pending(step)
	if question.is_empty() or choice not in question["options"]:
		return {}
	var correct: bool = choice == question["answer"]
	var points: int = 0
	if correct:
		correct_count += 1
		streak += 1
		points = 100 + mini(streak, 2) * 25 - (25 if hinted.has(step) else 0)
		score += points
	else:
		streak = 0
	answered[step] = correct
	return {"correct": correct, "points": points, "answer": question["answer"], "rule": question["hint"]}

func use_hint(step: int) -> String:
	var question: Dictionary = pending(step)
	if question.is_empty():
		return ""
	hinted[step] = true
	return question["hint"]

func stars() -> int:
	if correct_count == questions.size() and hinted.is_empty():
		return 3
	return 2 if correct_count >= 2 else 1

func _concept_questions(index: int) -> Array:
	if index == 7:
		return [
			_question("How many source/target pairs does a 6-department matrix contain?", "36", ["6", "12", "36"], "Every source has six possible targets, including itself."),
			_question("HQ -> Forms costs 3; Forms -> Lost costs -2. What is the combined cost?", "1 credit", ["1 credit", "5 credits", "6 credits"], "Add the original costs, including the negative rebate."),
			_question("Add Lost -> Delivery (4) to that route. What is HQ -> Delivery?", "5 credits", ["5 credits", "9 credits", "12 credits"], "The route is 3 + (-2) + 4.")
		]
	return [
		_question("Forms -> Lost has a -2 credit rebate. Should Bellman-Ford keep the minus sign?", "Yes, keep -2", ["Yes, keep -2", "Convert to +2", "Delete the lane"], "Bellman-Ford supports negative edge weights."),
		_question("HQ -> Forms costs 3; Forms -> Lost costs -2. What is the new distance to Lost?", "1 credit", ["1 credit", "5 credits", "7 credits"], "Relaxation uses distance to Forms plus the original edge cost."),
		_question("A full pass changes no distances. What can Bellman-Ford do?", "Finish early", ["Finish early", "Start over", "Ignore the result"], "If no relaxation improves a distance, further identical passes cannot help.")
	]

func _question(prompt: String, solution: String, options: Array, hint: String) -> Dictionary:
	var shuffled: Array = options.duplicate()
	shuffled.shuffle()
	return {"prompt": prompt, "answer": solution, "options": shuffled, "hint": hint, "node_choice": false}
