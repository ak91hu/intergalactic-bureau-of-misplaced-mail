class_name TreeScene
extends Control

var model := TreeAlgorithms.new()
var frames: Array = []
var values: Array = []
var cursor: int = -1
var mistakes: int = 0
var hints: int = 0
var assisted: bool = false
var auto_play: bool = false
var interval: float = 1.6
var elapsed: float = 0
var _saved: bool = false
var _hinted: Dictionary = {}
var _options: Array = []
var board: TreeBoard
var header: HBoxContainer
var sidebar: PanelContainer
var bottom: PanelContainer
var controls: HBoxContainer
var question: Label
var explanation: Label
var metrics: Label
var progress: Label
var choices: VBoxContainer
var auto_button: Button
var next_button: Button
var undo_button: Button
var popup: PanelContainer
var guide_card: BureauGuide
var _feedback_title: String = "Kezdjük együtt!"
var _feedback_tone: String = "info"
var _save_error: Error = OK
var retry_save_button: Button

func _ready() -> void:
	values = TreeAlgorithms.sequence(GameState.tree_tier,GameState.tree_variant)
	frames = model.build(GameState.tree_kind,values,values[values.size()/2] if GameState.tree_tier < 2 else 99)
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func _build() -> void:
	BureauTheme.apply_theme(self)
	var background := BureauBackdrop.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header = BureauTheme.row(self,12)
	var home := BureauTheme.button("< Akadémia")
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://MenuScene.tscn"))
	header.add_child(home)
	var title := BureauTheme.column(header,2)
	title.add_child(BureauTheme.label("IBMM / ADATSZERKEZETEK",12,BureauTheme.CYAN))
	title.add_child(BureauTheme.label(TreeAlgorithms.NAMES[GameState.tree_kind],28))
	BureauTheme.spacer(header)
	progress = BureauTheme.label("",14,BureauTheme.GOLD)
	header.add_child(progress)
	board = TreeBoard.new()
	add_child(board)
	sidebar = PanelContainer.new()
	sidebar.add_theme_stylebox_override("panel",BureauTheme.panel())
	add_child(sidebar)
	var side_root := BureauTheme.column(sidebar,10)
	guide_card = BureauGuide.new()
	side_root.add_child(guide_card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_root.add_child(scroll)
	var side := BureauTheme.column(scroll,12)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(BureauTheme.label("CSOMAGOK BESZÚRÁSI SORRENDJE",12,BureauTheme.CYAN))
	side.add_child(BureauTheme.label(TreeAlgorithms._numbers(values),18,BureauTheme.GOLD,true))
	metrics = BureauTheme.label("",14,BureauTheme.MUTED,true)
	question = BureauTheme.label("",20,BureauTheme.INK,true)
	side.add_child(question)
	choices = BureauTheme.column(side,8)
	side.add_child(metrics)
	var hint := BureauTheme.button("Segítség [H]")
	hint.pressed.connect(_hint)
	side.add_child(hint)
	var guide := BureauTheme.button("Szabályok és magyarázat [I]")
	guide.pressed.connect(_guide)
	side.add_child(guide)
	next_button = BureauTheme.button("Következő szint >",true)
	next_button.pressed.connect(_next)
	side.add_child(next_button)
	var fresh := BureauTheme.button("Új beszúrási sorrend")
	fresh.pressed.connect(func(): GameState.tree_variant += 1; get_tree().reload_current_scene())
	side.add_child(fresh)
	retry_save_button = BureauTheme.button("Mentés újrapróbálása")
	retry_save_button.pressed.connect(func(): _save_error = GameState.save_progress(); _refresh())
	retry_save_button.visible = false
	side.add_child(retry_save_button)
	bottom = PanelContainer.new()
	bottom.add_theme_stylebox_override("panel",BureauTheme.panel(Color("122338")))
	add_child(bottom)
	var why_scroll := ScrollContainer.new()
	why_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom.add_child(why_scroll)
	var text := BureauTheme.column(why_scroll,7)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(BureauTheme.label("MI TÖRTÉNT ÉS MIÉRT?",12,BureauTheme.CYAN))
	explanation = BureauTheme.label("Építs csomagnyilvántartást! Válaszd ki a helyes összehasonlítást, forgatást vagy színjavítást. Az automata végigmutatja a lépéseket; a kézi mód döntésekkel tanít.",16,BureauTheme.INK,true)
	text.add_child(explanation)
	controls = BureauTheme.row(self,10)
	undo_button = BureauTheme.button("< Vissza [Z]")
	undo_button.pressed.connect(_undo)
	undo_button.tooltip_text = "Visszaállítja az előző fát. Ez a menet pont nélküli gyakorlásra vált; a korábbi eredményed megmarad."
	controls.add_child(undo_button)
	auto_button = BureauTheme.button("Automata [A]",true)
	auto_button.pressed.connect(_toggle_auto)
	auto_button.tooltip_text = "Bemutatja a helyes lépéseket, pont és érem nélkül. A-val bármikor szüneteltetheted."
	controls.add_child(auto_button)
	var speed := OptionButton.new()
	for label: String in ["Lassú", "Normál", "Gyors"]: speed.add_item(label)
	speed.select(1)
	speed.item_selected.connect(func(index: int): interval = [2.6,1.6,0.65][index]; elapsed = 0)
	controls.add_child(speed)
	var restart := BureauTheme.button("Újrakezdés [R]")
	restart.pressed.connect(func(): get_tree().reload_current_scene())
	controls.add_child(restart)
	controls.add_child(BureauTheme.label("1–3: választás · Enter: egyetlen lépés",12,BureauTheme.MUTED))

func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	header.position = Vector2(24,20)
	header.size = Vector2(view.x-48,58)
	board.position = Vector2(24,102)
	board.size = Vector2(view.x-426,view.y-328)
	sidebar.position = Vector2(view.x-378,102)
	sidebar.size = Vector2(354,view.y-190)
	bottom.position = Vector2(24,view.y-210)
	bottom.size = Vector2(view.x-426,122)
	controls.position = Vector2(24,view.y-68)
	controls.size = Vector2(view.x-48,44)

func _frame() -> Dictionary:
	return frames[cursor] if cursor >= 0 else {"nodes":{},"root":-1,"focus":-1,"kind":GameState.tree_kind,"rotations":0,"recolors":0,"stable":true}

func _refresh() -> void:
	var complete: bool = cursor >= frames.size()-1
	var frame: Dictionary = _frame()
	board.set_frame(frame)
	progress.text = "%s · %d / %d lépés" % ["BEMUTATÓ / GYAKORLÁS" if assisted else CourierLessons.TIERS[GameState.tree_tier],cursor+1,frames.size()]
	metrics.text = "Csúcsok: %d  ·  magasság: %d\nForgatások: %d  ·  színjavítások: %d\n%s" % [frame["nodes"].size(),_height(frame["nodes"],frame["root"]),frame["rotations"],frame["recolors"],_invariants(frame)]
	undo_button.disabled = cursor < 0
	auto_button.disabled = complete
	next_button.visible = complete
	for child: Node in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	_options.clear()
	if complete:
		_stop_auto()
		question.text = "Archívum kész!"
		var score: int = maxi(100,1000-mistakes*40-hints*60)
		if not assisted:
			question.text += "\n%d pont · %d hiba · %d segítség" % [score,mistakes,hints]
			if not _saved:
				GameState.record_tree(GameState.tree_kind,GameState.tree_tier,score,3 if mistakes == 0 and hints == 0 else (2 if mistakes <= 3 else 1))
				_save_error = GameState.last_save_error
				_saved = true
		else: question.text += "\nBemutató/gyakorlás: nincs pont vagy érem."
		retry_save_button.visible = _save_error != OK
		_update_guidance()
		return
	retry_save_button.visible = false
	var upcoming: Dictionary = frames[cursor+1]
	question.text = upcoming["prompt"]
	var action: String = upcoming["action"]
	var distractors: Array
	match action:
		"left","right","found","missing": distractors = ["left","right","found" if action != "missing" else "missing"]
		"rotate_left","rotate_right": distractors = ["rotate_left","rotate_right","recolor" if GameState.tree_kind == 2 else "settled"]
		"recolor","black_root": distractors = [action,"rotate_left","rotate_right"]
		"settled": distractors = [action,"rotate_left","rotate_right"]
		"insert": distractors = [action,"left","right"]
		_: distractors = [action]
	var rng := RandomNumberGenerator.new()
	rng.seed = 8123 + cursor*17 + GameState.tree_kind*7
	while not distractors.is_empty():
		var index: int = rng.randi_range(0,distractors.size()-1)
		_options.append(distractors.pop_at(index))
	for index: int in _options.size():
		var option: String = _options[index]
		var button := BureauTheme.button("%d. %s" % [index+1,TreeAlgorithms.ACTIONS[option]])
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(func(): _choose(option))
		choices.add_child(button)
	_update_guidance()

func _choose(action: String, automatic: bool = false) -> void:
	if _popup_open() or cursor >= frames.size()-1: return
	if not automatic: _stop_auto()
	var upcoming: Dictionary = frames[cursor+1]
	if action not in _options:
		_feedback_title = "Ez a művelet most nem választható"
		_feedback_tone = "warning"
		explanation.text = "A fa nem változott. A jobb oldali gombok az aktuális kérdés lehetséges válaszait mutatják."
		_update_guidance()
		return
	if action != upcoming["action"]:
		mistakes += 1
		_feedback_title = "Próbáld újra — a fa nem változott"
		_feedback_tone = "warning"
		explanation.text = "Ezt választottad: %s. %s" % [TreeAlgorithms.ACTIONS[action],_reason_before(upcoming)]
		_update_guidance()
		BureauAudio.play_cue("wrong")
		return
	cursor += 1
	_feedback_title = ("Bemutató: " if automatic else "Lépés kész: ") + TreeAlgorithms.ACTIONS[action]
	_feedback_tone = "info"
	explanation.text = upcoming["explanation"]
	BureauAudio.play_cue("click")
	_refresh()
	if cursor == frames.size()-1: BureauAudio.play_cue("complete")

func _reason_before(frame: Dictionary) -> String:
	match frame["action"]:
		"left","right": return "Hasonlítsd össze a keresett/beszúrandó kulcsot a jelenlegi csúccsal: kisebb → balra, nagyobb → jobbra."
		"rotate_left","rotate_right": return "A kérdés megadja a javítás okát. Balra forgatáskor a jobb gyermek, jobbra forgatáskor a bal gyermek kerül feljebb."
		"recolor": return "A piros szülő és piros nagybácsi átszínezést igényel. Fekete nagybácsinál a vonalas esetet forgatás is követi."
		"black_root": return "A piros-fekete fa gyökere mindig fekete."
		_: return frame["prompt"]

func _undo() -> void:
	if _popup_open() or cursor < 0: return
	_stop_auto()
	assisted = true
	cursor -= 1
	_feedback_title = "Visszaléptél — most pont nélkül gyakorolhatsz"
	_feedback_tone = "info"
	explanation.text = "Visszaléptél: a korábbi faállapotot újra megvizsgálhatod. A gyakorlás nem írja felül a legjobb eredményedet."
	_refresh()

func _hint() -> void:
	if _popup_open() or cursor >= frames.size()-1: return
	_stop_auto()
	var repeated: bool = _hinted.has(cursor)
	if not _hinted.has(cursor):
		_hinted[cursor] = true
		hints += 1
	explanation.text = "Következő helyes lépés: " + TreeAlgorithms.ACTIONS[frames[cursor+1]["action"]] + ". " + _reason_before(frames[cursor+1])
	_feedback_title = "Ugyanaz a segítség — nincs újabb levonás" if repeated else "Segítek: nézd meg az alsó magyarázatot"
	_feedback_tone = "info"
	_update_guidance()

func _toggle_auto() -> void:
	if _popup_open() or cursor >= frames.size()-1: return
	if auto_play:
		_stop_auto()
		_feedback_title = "Bemutató szüneteltetve — van időd átnézni"
	else:
		assisted = true
		auto_play = true
		elapsed = 0
		auto_button.text = "Szünet [A]"
		_feedback_title = "Bemutató elindult — figyeld a változó fát"
	_feedback_tone = "info"
	_refresh()

func _stop_auto() -> void:
	auto_play = false
	elapsed = 0
	auto_button.text = "Automata [A]"

func _process(delta: float) -> void:
	if not auto_play or _popup_open(): return
	elapsed += delta
	if elapsed >= interval:
		elapsed = 0
		_choose(frames[cursor+1]["action"],true)

func _guide() -> void:
	_stop_auto()
	_feedback_title = "A lejátszás szünetel, amíg olvasol"
	_feedback_tone = "info"
	_update_guidance()
	if _popup_open(): _close_guide(); return
	popup = PanelContainer.new()
	add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.offset_left = 100
	popup.offset_right = -100
	popup.offset_top = 110
	popup.offset_bottom = -110
	popup.add_theme_stylebox_override("panel",BureauTheme.panel(BureauTheme.SURFACE,BureauTheme.CYAN,26))
	var body := BureauTheme.column(popup,16)
	body.add_child(BureauTheme.label(TreeAlgorithms.NAMES[GameState.tree_kind] + " / Miért működik?",27))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var text := BureauTheme.column(scroll,18)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(BureauTheme.label(TreeAlgorithms.RULES[GameState.tree_kind],21,BureauTheme.INK,true))
	text.add_child(BureauTheme.label("KERESÉS ÉS BESZÚRÁS",13,BureauTheme.CYAN))
	text.add_child(BureauTheme.label("BST: O(h), a legrosszabb esetben O(n). AVL és piros-fekete fa: O(log n) a legrosszabb esetben is. Az inorder bejárás O(n), és minden kulcsot növekvő sorrendben ad vissza. A forgatás helyi művelet, O(1).",19,BureauTheme.INK,true))
	text.add_child(BureauTheme.label("A küldetés beszúrást, egyensúlyozást, keresést és inorder bejárást tanít. A színjavítás köztes lépéseiben átmenetileg sérülhet egy szabály; a „beszúrás kész” pontnál mindnek teljesülnie kell. A NIL-kapcsolatok fekete levelek.\n\nVálaszolj 1–3-mal vagy gombbal. A: automata/szünet; Z: vissza; H: segítség; R: újrakezdés. Az automata és a visszalépés pont nélküli gyakorlás. Újrakezdéssel ismét kézzel teljesítheted a küldetést.",18,BureauTheme.MUTED,true))
	var close := BureauTheme.button("Bezárás [Esc / I]")
	close.pressed.connect(_close_guide)
	body.add_child(close)

func _popup_open() -> bool:
	return is_instance_valid(popup) and not popup.is_queued_for_deletion()

func _close_guide() -> void:
	popup.queue_free()
	_feedback_title = "Folytathatod — a fa ugyanott vár"
	_update_guidance()

func _update_guidance() -> void:
	var message: String
	var next: String = "Most: válaszolj 1–3-mal vagy gombbal. H: segítség · I: miért? A részletes indoklás lent látszik."
	var title: String = _feedback_title
	var tone: String = _feedback_tone
	if cursor >= frames.size()-1:
		title = "Elkészült a csomagarchívum!"
		if assisted:
			message = "Végignézted vagy visszajátszottad a megoldást. Ez a menet nem ad pontot; a korábbi érmed megmarad."
			next = "Újrakezdés [R]: oldd meg saját döntésekkel. A Következő szint gombbal tovább is léphetsz."
		elif _save_error != OK:
			title = "Kész a feladat, de a mentés nem sikerült"
			message = "Az eredmény most csak az alkalmazás memóriájában van. Bezárás előtt próbáld meg újra elmenteni."
			next = "A Mentés újrapróbálása gombot a jobb oldali listában találod."
			tone = "warning"
		else:
			message = "Eredményed mentettük ezen az eszközön. Megtanultad a beszúrás, a keresés és az inorder bejárás lépéseit."
			next = "Nézd meg a végső fát és a pontszámodat, majd válassz következő szintet vagy új sorrendet."
	else:
		var action: String = frames[cursor+1]["action"]
		match action:
			"left","right": message = "Most egy összehasonlítás dönt: kisebb kulcsot balra, nagyobbat jobbra keresünk. A másik részfát kizárhatjuk."
			"insert": message = "Megtaláltuk az új kulcs üres helyét. Beszúrás után külön ellenőrizzük, kell-e egyensúly- vagy színjavítás."
			"rotate_left","rotate_right": message = "Most a fa alakját javítjuk. Forgatáskor egy gyermek feljebb kerül, de a kulcsok növekvő sorrendje megmarad."
			"recolor","black_root": message = "Most a színszabályokat javítjuk. Figyeld a piros szülőt, a nagybácsit és a gyökeret; a fa helyes sorrendje nem változik."
			"settled": message = "A beszúrás utáni ellenőrzésnél járunk. Ha a fa szabályos, továbbléphetünk; felesleges forgatásra nincs szükség."
			"found","missing": message = "A keresés eredményéről döntünk: egyező kulcsnál megvan a csomag, üres NIL-kapcsolatnál nincs a fában."
			_: message = "Végül bejárjuk a fát. Gondold végig, melyik sorrend adja a kulcsokat a legkisebbtől a legnagyobbig."
		if auto_play:
			next = "Automata fut · A: szünet · a sebességet alul állíthatod. Ez a menet nem pontozott."
		elif assisted:
			next += " Pont nélküli gyakorlás · A: automata folytatása."
	guide_card.show_message(title,message,next,tone)

func _next() -> void:
	if GameState.tree_tier < 2: GameState.tree_tier += 1
	else:
		GameState.tree_tier = 0
		GameState.tree_kind = (GameState.tree_kind+1)%3
	GameState.tree_variant = 0
	get_tree().reload_current_scene()

func _height(nodes: Dictionary, key: int) -> int:
	if key == -1: return 0
	return 1 + maxi(_height(nodes,nodes[key]["left"]),_height(nodes,nodes[key]["right"]))

func _invariants(frame: Dictionary) -> String:
	if frame["nodes"].is_empty(): return "Üres fa: kezdődhet az első beszúrás."
	if GameState.tree_kind == 0: return "Szabály: bal < gyökér < jobb. A BST nem egyensúlyoz."
	if GameState.tree_kind == 1:
		var worst: int = 0
		for key: int in frame["nodes"]: worst = maxi(worst,absi(_height(frame["nodes"],frame["nodes"][key]["left"])-_height(frame["nodes"],frame["nodes"][key]["right"])))
		return "Legnagyobb |egyensúlyfaktor|: %d %s" % [worst,"✓" if worst <= 1 else "→ javítás kell"]
	var red_pairs: int = 0
	for key: int in frame["nodes"]:
		if not frame["nodes"][key]["red"]: continue
		for side: String in ["left","right"]:
			var child: int = frame["nodes"][key][side]
			if child != -1 and frame["nodes"][child]["red"]: red_pairs += 1
	var black_heights: Array = []
	_black_heights(frame["nodes"],frame["root"],0,black_heights)
	return "Gyökér: %s · piros–piros: %d\nFekete csúcsok/út (NIL-lel): %s%s" % ["piros → javítás kell" if frame["nodes"][frame["root"]]["red"] else "fekete ✓",red_pairs,TreeAlgorithms._numbers(black_heights)," ✓" if black_heights.size() == 1 else " → javítás közben"]

func _black_heights(nodes: Dictionary, key: int, count: int, result: Array) -> void:
	if key == -1:
		if count+1 not in result: result.append(count+1)
		return
	var total: int = count + (0 if nodes[key]["red"] else 1)
	_black_heights(nodes,nodes[key]["left"],total,result)
	_black_heights(nodes,nodes[key]["right"],total,result)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if _popup_open():
		if event.keycode in [KEY_ESCAPE,KEY_I]: _close_guide()
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_ESCAPE: get_tree().change_scene_to_file("res://MenuScene.tscn")
		KEY_A: _toggle_auto()
		KEY_Z,KEY_BACKSPACE: _undo()
		KEY_H: _hint()
		KEY_I: _guide()
		KEY_R: get_tree().reload_current_scene()
		KEY_1,KEY_2,KEY_3:
			var index: int = event.keycode-KEY_1
			if index < _options.size(): _choose(_options[index])
		KEY_SPACE,KEY_ENTER:
			if _options.size() == 1: _choose(_options.front())
		_: return
	get_viewport().set_input_as_handled()
