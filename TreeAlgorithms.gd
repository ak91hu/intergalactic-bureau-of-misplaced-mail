class_name TreeAlgorithms
extends RefCounted

const NAMES: Array[String] = ["Bináris keresőfa", "AVL-fa", "Piros-fekete fa"]
const SUBTITLES: Array[String] = ["Rendezett csomagnyilvántartás", "Egyensúly forgatásokkal", "Színek, szabályok, gyors keresés"]
const RULES: Array[String] = [
	"Balra minden kulcs kisebb, jobbra minden kulcs nagyobb. Kereséskor minden összehasonlítás egy teljes részfát kizár. Az egyszerű BST nem egyensúlyoz: rendezett beszúrásnál lánccá nyúlhat.",
	"Bináris keresőfa, amelynek minden csúcsán |bal magasság − jobb magasság| ≤ 1. A beszúrás után az első kiegyensúlyozatlan őst egyszeres vagy kettős forgatással javítjuk. A forgatás megőrzi az inorder sorrendet.",
	"A gyökér és minden hiányzó NIL-levél fekete. Piros csúcsnak nem lehet piros gyermeke. Minden csúcsból a NIL-levelekhez vezető utak ugyanannyi fekete csúcsot tartalmaznak. Beszúráskor piros csúcsot adunk hozzá, majd átszínezéssel és forgatással javítunk."
]
const ACTIONS: Dictionary = {
	"left":"Balra lépek", "right":"Jobbra lépek", "insert":"Beszúrom az új kulcsot",
	"rotate_left":"Balra forgatok", "rotate_right":"Jobbra forgatok",
	"recolor":"Átszínezem a csúcsokat", "black_root":"Feketére színezem a gyökeret",
	"settled":"Kész: a beszúrás szabályos", "found":"Megtaláltam a kulcsot",
	"missing":"Nincs ilyen kulcs a fában", "inorder":"Bal részfa → gyökér → jobb részfa"
}
var kind: int = 2
var nodes: Dictionary = {}
var root_key: int = -1
var trace: Array = []
var rotations: int = 0
var recolors: int = 0
var _inserting: int = -1

static func sequence(tier: int, variant: int = 0) -> Array:
	var values: Array = [[30,20,10,25,40,50], [41,38,31,12,19,8,45,50], [20,10,30,5,15,25,35,1,6,14,16]][clampi(tier,0,2)].duplicate()
	if variant > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 73129 + tier * 109 + variant * 997
		for index: int in range(values.size()-1,0,-1):
			var other: int = rng.randi_range(0,index)
			var temp: int = values[index]
			values[index] = values[other]
			values[other] = temp
	return values

func build(tree_kind: int, values: Array, search_key: int) -> Array:
	kind = clampi(tree_kind,0,2)
	nodes.clear()
	trace.clear()
	root_key = -1
	rotations = 0
	recolors = 0
	for value: int in values: _insert(value)
	_search(search_key)
	_emit("inorder", "Melyik bejárás adja a kulcsokat növekvő sorrendben?", "Az inorder bejárás eredménye: " + _numbers(inorder()) + ". A forgatások ezt a sorrendet végig megőrizték.", root_key, true)
	return trace.duplicate(true)

func _insert(value: int) -> void:
	_inserting = value
	var parent: int = -1
	var current: int = root_key
	while current != -1:
		parent = current
		if value == current:
			_emit("found", "%d már szerepel. Beszúrjuk még egyszer?" % value, "A kulcsok egyediek: a meglévő %d kulcsot megtartjuk." % value, current, true)
			return
		var left: bool = value < current
		_emit("left" if left else "right", "%d beszúrása: %d csúcsból merre lépünk?" % [value,current], "%d %s %d, ezért a %s részfában folytatjuk." % [value,"<" if left else ">",current,"bal" if left else "jobb"], current)
		current = nodes[current]["left" if left else "right"]
	nodes[value] = {"left":-1,"right":-1,"parent":parent,"red":kind == 2}
	if parent == -1: root_key = value
	else: nodes[parent]["left" if value < parent else "right"] = value
	_emit("insert", "%d helyén üres kapcsolatot találtunk. Mi következik?" % value, "%d bekerült a fába%s." % [value," piros csúcsként; most ellenőrizzük a színszabályokat" if kind == 2 else ""], value)
	if kind == 2: _fix_red_black(value)
	elif kind == 1: _fix_avl(value)
	_emit("settled", "%d beszúrása után teljesülnek a fa szabályai. Mi következik?" % value, "%d beszúrása kész. %s" % [value, "Minden út fekete magassága azonos, nincs piros–piros kapcsolat." if kind == 2 else ("Minden csúcs egyensúlyfaktora −1, 0 vagy +1." if kind == 1 else "A bal < gyökér < jobb rendezési szabály teljesül.")], value, true)

func _fix_red_black(value: int) -> void:
	var z: int = value
	while z != root_key and _red(nodes[z]["parent"]):
		var parent: int = nodes[z]["parent"]
		var grand: int = nodes[parent]["parent"]
		var parent_left: bool = nodes[grand]["left"] == parent
		var uncle: int = nodes[grand]["right" if parent_left else "left"]
		if _red(uncle):
			nodes[parent]["red"] = false
			nodes[uncle]["red"] = false
			nodes[grand]["red"] = true
			recolors += 1
			_emit("recolor", "A szülő (%d) és a nagybácsi (%d) is piros. Hogyan javítunk?" % [parent,uncle], "A szülő és a nagybácsi fekete, a nagyszülő (%d) piros lesz. A fekete magasság nem változik; a javítást feljebb folytatjuk." % grand, grand)
			z = grand
		else:
			if z == nodes[parent]["right" if parent_left else "left"]:
				z = parent
				_rotate(z, parent_left, "A piros csúcsok háromszöget alkotnak, a nagybácsi fekete/NIL. Először egy vonalba rendezzük őket.")
				parent = nodes[z]["parent"]
				grand = nodes[parent]["parent"]
			nodes[parent]["red"] = false
			nodes[grand]["red"] = true
			recolors += 1
			_emit("recolor", "A nagybácsi fekete, a piros csúcsok egy vonalban állnak. Milyen színjavítás kell a forgatás előtt?", "A szülő (%d) fekete, a nagyszülő (%d) piros lesz; ezután a nagyszülő körül forgatunk." % [parent,grand], parent)
			_rotate(grand, not parent_left, "A fekete nagybácsi melletti vonalas esetet a nagyszülő forgatása oldja fel.")
	if _red(root_key):
		nodes[root_key]["red"] = false
		recolors += 1
		_emit("black_root", "A gyökér (%d) piros. Melyik szabályt állítjuk helyre?" % root_key, "A gyökér mindig fekete. Minden lefelé vezető út ugyanazzal az egy fekete csúccsal bővül.", root_key)

func _fix_avl(value: int) -> void:
	var current: int = nodes[value]["parent"]
	while current != -1:
		var balance: int = height(nodes[current]["left"]) - height(nodes[current]["right"])
		if balance > 1:
			var left: int = nodes[current]["left"]
			if value > left: _rotate(left, true, "Bal–jobb eset: először a bal gyermeket forgatjuk balra.")
			_rotate(current, false, "%d egyensúlyfaktora +2: a bal részfa túl magas. Jobbra forgatunk." % current)
			break
		elif balance < -1:
			var right: int = nodes[current]["right"]
			if value < right: _rotate(right, false, "Jobb–bal eset: először a jobb gyermeket forgatjuk jobbra.")
			_rotate(current, true, "%d egyensúlyfaktora −2: a jobb részfa túl magas. Balra forgatunk." % current)
			break
		current = nodes[current]["parent"]

func _rotate(pivot: int, left: bool, reason: String) -> void:
	var side: String = "right" if left else "left"
	var opposite: String = "left" if left else "right"
	var promoted: int = nodes[pivot][side]
	var middle: int = nodes[promoted][opposite]
	var parent: int = nodes[pivot]["parent"]
	nodes[pivot][side] = middle
	if middle != -1: nodes[middle]["parent"] = pivot
	nodes[promoted]["parent"] = parent
	if parent == -1: root_key = promoted
	else: nodes[parent]["left" if nodes[parent]["left"] == pivot else "right"] = promoted
	nodes[promoted][opposite] = pivot
	nodes[pivot]["parent"] = promoted
	rotations += 1
	_emit("rotate_left" if left else "rotate_right", reason + " Melyik forgatás következik?", "%s forgatás %d körül: %d feljebb kerül, a középső részfa a helyére kapcsolódik. Az inorder sorrend változatlan." % ["Balra" if left else "Jobbra",pivot,promoted], promoted)

func _search(value: int) -> void:
	_inserting = -1
	var current: int = root_key
	while current != -1:
		if value == current:
			_emit("found", "%d keresése: a jelenlegi kulcs %d. Mi az eredmény?" % [value,current], "A kulcs egyezik: a %d azonosítójú csomag megvan." % value, current, true)
			return
		var left: bool = value < current
		_emit("left" if left else "right", "%d keresése: %d csúcsból merre indulunk?" % [value,current], "%d %s %d, ezért a %s részfát vizsgáljuk; a másik részfa kizárható." % [value,"<" if left else ">",current,"bal" if left else "jobb"], current, true)
		current = nodes[current]["left" if left else "right"]
	_emit("missing", "%d keresése üres NIL-kapcsolathoz ért. Mi az eredmény?" % value, "A keresett kulcs nincs a fában. Az üres kapcsolat megbízhatóan lezárja a keresést.", -1, true)

func _emit(action: String, prompt: String, explanation: String, focus: int, stable: bool = false) -> void:
	trace.append({"action":action,"prompt":prompt,"explanation":explanation,"nodes":nodes.duplicate(true),"root":root_key,"focus":focus,"inserting":_inserting,"stable":stable,"rotations":rotations,"recolors":recolors,"kind":kind})

func _red(key: int) -> bool:
	return key != -1 and nodes[key]["red"]

func height(key: int) -> int:
	if key == -1: return 0
	return 1 + maxi(height(nodes[key]["left"]),height(nodes[key]["right"]))

func inorder(key: int = -2) -> Array:
	if key == -2: key = root_key
	if key == -1: return []
	return inorder(nodes[key]["left"]) + [key] + inorder(nodes[key]["right"])

static func _numbers(values: Array) -> String:
	var strings := PackedStringArray()
	for value: int in values: strings.append(str(value))
	return " · ".join(strings)
