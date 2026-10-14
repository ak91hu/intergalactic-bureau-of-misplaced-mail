class_name CourierScene
extends Control

var session := CourierSession.new()
var board: CourierBoard
var header: HBoxContainer
var stages: HBoxContainer
var sidebar: PanelContainer
var code_panel: PanelContainer
var footer: HBoxContainer
var action_grid: GridContainer
var completion_controls: VBoxContainer
var phase_label: Label
var budget_label: Label
var feedback_label: Label
var frontier_label: Label
var state_label: Label
var lesson_label: Label
var code_box: VBoxContainer
var code_title: Label
var cost_bar: ProgressBar
var undo_button: Button
var hint_button: Button
var matrix_button: Button
var score_label: Label
var popup: PanelContainer
var _busy: bool = false
var _saved: bool = false
var _shown_phase: String = ""
var _choice_ids: Array = []
var auto_button: Button
var speed_button: OptionButton
var auto_play: bool = false
var demonstration: bool = false
var auto_interval: float = 1.6
var _auto_elapsed: float = 0.0
var _auto_dispatch: bool = false
var guide_card: BureauGuide
var _notice: String = ""
var _notice_tone: String = "info"
var _detail_override: String = ""
var _travel_from: String = ""
var _travel_to: String = ""
var _save_error: Error = OK

func _ready() -> void:
	session.setup(CourierLevels.generate(GameState.courier_algorithm, GameState.courier_tier, GameState.courier_variant))
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()

func _build() -> void:
	BureauTheme.apply_theme(self)
	var background := BureauBackdrop.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header = BureauTheme.row(self, 16)
	var home := BureauTheme.button("< Akadémia")
	home.pressed.connect(_home)
	header.add_child(home)
	var titles := BureauTheme.column(header, 2)
	titles.add_child(BureauTheme.label("IBMM / FUTÁRAKADÉMIA", 12, BureauTheme.CYAN))
	titles.add_child(BureauTheme.label(CourierLessons.TITLES[session.algorithm()], 25))
	BureauTheme.spacer(header)
	score_label = BureauTheme.label("", 14, BureauTheme.GOLD)
	header.add_child(score_label)
	stages = BureauTheme.row(self, 12)
	for text: String in ["1  Algoritmusterv", "2  Végrehajtás", "3  Tanulság"]:
		var label := BureauTheme.label(text, 14, BureauTheme.MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stages.add_child(label)
	board = CourierBoard.new()
	board.reduced_motion = GameState.reduced_motion
	add_child(board)
	board.set_session(session)
	board.choice_requested.connect(_select)
	board.inspection_requested.connect(_inspect)
	board.travel_finished.connect(_travel_done)
	sidebar = PanelContainer.new()
	sidebar.add_theme_stylebox_override("panel", BureauTheme.panel(BureauTheme.SURFACE, BureauTheme.BORDER, 18))
	add_child(sidebar)
	var side := BureauTheme.column(sidebar, 10)
	var top := BureauTheme.row(side)
	top.add_child(BureauTheme.label(CourierLessons.NAMES[session.algorithm()], 25, CourierLessons.COLORS[session.algorithm()]))
	BureauTheme.spacer(top)
	top.add_child(BureauTheme.label(CourierLessons.TIERS[session.level["tier"]], 12, BureauTheme.MUTED))
	phase_label = BureauTheme.label("", 12, BureauTheme.CYAN)
	side.add_child(phase_label)
	budget_label = BureauTheme.label("", 16, BureauTheme.INK, true)
	side.add_child(budget_label)
	cost_bar = ProgressBar.new()
	cost_bar.custom_minimum_size.y = 8
	cost_bar.show_percentage = false
	cost_bar.add_theme_stylebox_override("background", BureauTheme.panel(BureauTheme.BORDER, BureauTheme.BORDER, 0))
	cost_bar.add_theme_stylebox_override("fill", BureauTheme.panel(BureauTheme.CYAN, BureauTheme.CYAN, 0))
	side.add_child(cost_bar)
	guide_card = BureauGuide.new()
	side.add_child(guide_card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(scroll)
	var content := BureauTheme.column(scroll, 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(BureauTheme.label("LEGUTÓBBI LÉPÉS / MIÉRT?",12,BureauTheme.CYAN))
	feedback_label = BureauTheme.label("", 16, BureauTheme.INK, true)
	content.add_child(feedback_label)
	frontier_label = BureauTheme.label("", 15, BureauTheme.GOLD, true)
	content.add_child(frontier_label)
	action_grid = GridContainer.new()
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(action_grid)
	state_label = BureauTheme.label("", 14, BureauTheme.MUTED, true)
	content.add_child(state_label)
	completion_controls = BureauTheme.column(side, 8)
	completion_controls.visible = false
	code_panel = PanelContainer.new()
	code_panel.add_theme_stylebox_override("panel", BureauTheme.panel(Color("122338"), BureauTheme.BORDER, 12))
	add_child(code_panel)
	var code_column := BureauTheme.column(code_panel, 6)
	var code_header := BureauTheme.row(code_column, 8)
	code_title = BureauTheme.label("", 12, BureauTheme.CYAN)
	code_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_header.add_child(code_title)
	auto_button = BureauTheme.button("Automata [A]")
	auto_button.custom_minimum_size.y = 32
	auto_button.add_theme_font_size_override("font_size", 14)
	auto_button.tooltip_text = "Lépésenként bemutatja a helyes döntéseket. A bemutató nem ad pontot vagy érmet."
	auto_button.pressed.connect(_toggle_auto)
	code_header.add_child(auto_button)
	speed_button = OptionButton.new()
	for speed: String in ["Lassú", "Normál", "Gyors"]: speed_button.add_item(speed)
	speed_button.selected = 1
	speed_button.item_selected.connect(func(index: int): auto_interval = [2.6, 1.6, 0.65][index]; _auto_elapsed = 0)
	code_header.add_child(speed_button)
	code_box = BureauTheme.column(code_column, 3)
	footer = BureauTheme.row(self, 10)
	undo_button = BureauTheme.button("Visszalépés [Z]")
	undo_button.pressed.connect(_undo)
	undo_button.tooltip_text = "Az előző döntés előtti állapothoz lépsz vissza. A segítség és a hibák száma megmarad."
	footer.add_child(undo_button)
	hint_button = BureauTheme.button("Segítség [H]")
	hint_button.pressed.connect(_hint)
	hint_button.tooltip_text = "Megmutatja, mire figyelj a következő döntésnél. A bemutatót megállítja; döntésenként egyszer számít segítségnek."
	footer.add_child(hint_button)
	var guide := BureauTheme.button("Miért? [I]")
	guide.pressed.connect(func(): _open_guide(false))
	footer.add_child(guide)
	var journal := BureauTheme.button("Lépésnapló [L]")
	journal.pressed.connect(func(): _open_guide(true))
	footer.add_child(journal)
	matrix_button = BureauTheme.button("Mátrix / térkép [M]")
	matrix_button.visible = session.algorithm() == 7
	matrix_button.pressed.connect(_toggle_matrix)
	footer.add_child(matrix_button)
	BureauTheme.spacer(footer)
	lesson_label = BureauTheme.label("1–9: választás · Z: vissza · H: segítség", 12, BureauTheme.MUTED)
	footer.add_child(lesson_label)

func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	header.position = Vector2(24, 20)
	header.size = Vector2(view.x - 48, 58)
	stages.position = Vector2(30, 94)
	stages.size = Vector2(view.x - 60, 24)
	board.position = Vector2(24, 134)
	board.size = Vector2(view.x - 442, view.y - 364)
	code_panel.position = Vector2(24, view.y - 216)
	code_panel.size = Vector2(view.x - 442, 126)
	sidebar.position = Vector2(view.x - 404, 134)
	sidebar.size = Vector2(380, view.y - 224)
	footer.position = Vector2(24, view.y - 72)
	footer.size = Vector2(view.x - 48, 48)
	board.queue_redraw()

func _refresh() -> void:
	if not is_inside_tree(): return
	var phase_titles: Dictionary = {"briefing":"ELIGAZÍTÁS / olvasd el a célt", "search":"TERVEZÉS / válassz állomást", "edge_check":"RELAXÁLÁS / javít vagy marad?", "relax":"RELAXÁLÁS / %d. kör" % session.pass_number, "pass_end":"ELLENŐRZŐKÖR VÉGE", "order":"FELADÁSI SORREND / mi kész?", "network":"HÁLÓZATÉPÍTÉS / válassz kapcsolatot", "matrix":"MÁTRIX / válassz köztes pontot", "ready":"KÉSZ TERV / átveheted a csomagot", "delivery":"KÉZBESÍTÉS / te választasz útvonalat", "next_package":"MÁSODIK FELADÓ / új csomag", "complete":"JELENTÉS / küldetés teljesítve", "failed":"ÚJRATERVEZÉS / javítható terv", "anomaly":"NEGATÍV KÖR / nincs véges minimum"}
	phase_label.text = phase_titles.get(session.phase, session.phase)
	score_label.text = "BEMUTATÓ · nem pontozott" if demonstration else "visszajelzések: %d   ·   segítség: %d" % [session.mistakes, session.hints]
	if session.phase in ["complete", "anomaly", "failed"]: _stop_auto()
	auto_button.disabled = session.phase in ["complete", "anomaly", "failed"]
	var spent: int = session.tree_cost if CourierLessons.is_network(session.algorithm()) else session.route_cost
	budget_label.text = "%s → %s   /   %d. csomag\nKeret: %d %s   ·   felhasznált: %d" % [session.source(), session.target(), session.job_index + 1, session.budget(), session.unit(), spent]
	if session.algorithm() == 2:
		budget_label.text = "Feladva: %d / %d állomás\nElőfeltételek nélkül lehet továbbküldeni." % [session.order.size(), session.graph.nodes.size()]
	elif CourierLessons.is_network(session.algorithm()):
		budget_label.text = "Minden állomást összekötünk\nKeret: %d kredit · költség: %d" % [session.budget(),spent]
	cost_bar.max_value = session.graph.nodes.size() if session.algorithm() == 2 else maxi(1, session.budget())
	cost_bar.value = session.order.size() if session.algorithm() == 2 else maxi(0, spent)
	cost_bar.add_theme_stylebox_override("fill", BureauTheme.panel(BureauTheme.RED if spent > session.budget() else BureauTheme.CYAN, BureauTheme.CYAN, 0))
	feedback_label.text = _detail_override if not _detail_override.is_empty() else session.status
	feedback_label.add_theme_color_override("font_color", BureauTheme.RED if session.phase == "failed" else BureauTheme.INK)
	frontier_label.text = _frontier_text()
	frontier_label.visible = not frontier_label.text.is_empty()
	_refresh_actions()
	_refresh_code()
	state_label.text = _state_text()
	undo_button.disabled = _busy or session.history.is_empty() or session.phase == "complete"
	hint_button.disabled = _busy or session.phase in ["complete", "briefing"]
	if _shown_phase != session.phase:
		if session.phase == "matrix": board.matrix_visible = true
		elif session.phase in ["ready", "delivery", "next_package"]: board.matrix_visible = false
		_shown_phase = session.phase
	board.show_reference = (session.level["guided"] and session.phase in ["ready", "delivery"]) or session.phase in ["failed", "complete"]
	var stage: int = 2 if session.phase == "complete" else (1 if session.phase in ["delivery", "order", "network", "failed", "next_package"] else 0)
	for index: int in range(3):
		var stage_label: Label = stages.get_child(index)
		stage_label.add_theme_color_override("font_color", BureauTheme.CYAN if index == stage else BureauTheme.MUTED)
		var stage_style := BureauTheme.panel(Color("17333d") if index == stage else Color(BureauTheme.SURFACE, 0.65), Color("37665f") if index == stage else Color(BureauTheme.BORDER, 0.4), 7)
		stage_style.set_corner_radius_all(8)
		stage_style.shadow_size = 0
		stage_label.add_theme_stylebox_override("normal", stage_style)
	board.queue_redraw()
	if session.phase == "complete" and not _busy and not _saved:
		_saved = true
		if not demonstration: GameState.record_courier(session.algorithm(), session.level["tier"], session.result["score"], session.result["stars"])
		if not demonstration: _save_error = GameState.last_save_error
		_cue("success")
		if _save_error != OK: _refresh_actions()
	_update_guidance()

func _clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh_actions() -> void:
	_clear(action_grid)
	_clear(completion_controls)
	completion_controls.visible = session.phase == "complete"
	_choice_ids.clear()
	action_grid.columns = 2 if session.phase in ["search", "order", "network", "matrix"] else 1
	if session.phase == "complete":
		feedback_label.text = _report_text()
		if demonstration: feedback_label.text = "BEMUTATÓ / pont és érem nélkül\n\n" + session.result["takeaway"] + "\n\nA jelentés megtekintéséhez és éremhez kezdd újra, és válaszd ki te a lépéseket."
		frontier_label.visible = false
		var next := BureauTheme.button("Következő pálya >", true)
		next.pressed.connect(_next)
		next.disabled = _busy
		completion_controls.add_child(next)
		var fresh := BureauTheme.button("Új hálózat ezen a szinten")
		fresh.pressed.connect(_fresh)
		fresh.disabled = _busy
		completion_controls.add_child(fresh)
		if demonstration:
			var retry := BureauTheme.button("Újra, saját döntésekkel")
			retry.pressed.connect(func(): get_tree().reload_current_scene())
			completion_controls.add_child(retry)
		if _saved and _save_error != OK:
			var save_again := BureauTheme.button("Mentés újrapróbálása")
			save_again.pressed.connect(_retry_save)
			completion_controls.add_child(save_again)
		return
	var options: Array = session.choices()
	for index: int in options.size():
		var option: Dictionary = options[index]
		var id: String = option["id"]
		_choice_ids.append(id)
		var button := BureauTheme.button(("%d. " % (index + 1) if index < 9 else "") + option["label"] + "\n" + option["detail"], options.size() == 1)
		button.add_theme_font_size_override("font_size", 14)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.x = 145 if action_grid.columns == 2 else 0
		button.custom_minimum_size.y = 62
		button.tooltip_text = option["label"] + ": " + option["detail"]
		button.disabled = _busy
		button.pressed.connect(func(): _select(id))
		action_grid.add_child(button)

func _refresh_code() -> void:
	_clear(code_box)
	code_title.text = "PSZEUDOKÓD / " + CourierLessons.NAMES[session.algorithm()]
	var code: Array = CourierLessons.PSEUDOCODE[session.algorithm()]
	var current_line: int = session.code_line()
	var start: int = clampi(current_line - 1, 0, maxi(0, code.size() - 3))
	for index: int in range(start, mini(start + 3, code.size())):
		var label := BureauTheme.label(("> " if index == current_line else "  ") + str(index + 1) + "  " + code[index], 14, BureauTheme.GOLD if index == current_line else BureauTheme.MUTED)
		code_box.add_child(label)

func _frontier_text() -> String:
	if session.phase in ["edge_check", "relax"]:
		var calc: Dictionary = session.calculation()
		return "ELLENŐRIZD: %s → %s\n%s + (%d) = %s   /   régi: %s" % [calc["from"], calc["to"], CourierSession.number(calc["source"]), calc["weight"], CourierSession.number(calc["candidate"]), CourierSession.number(calc["old"])]
	if session.phase == "search":
		var frontier: Array = session.frontier.duplicate()
		if session.algorithm() == 1: frontier.reverse()
		return ("SOR / eleje balra:  " if session.algorithm() == 0 else ("VEREM / teteje balra:  " if session.algorithm() == 1 else "VÁRAKOZÓ ÁLLOMÁSOK:  ")) + " | ".join(frontier)
	if session.phase == "order": return "SORREND: " + (" → ".join(session.order) if not session.order.is_empty() else "még üres")
	if session.phase == "network": return "Bekötve: %d / %d kapcsolat" % [session.tree.size(), session.graph.nodes.size() - 1]
	if session.phase == "matrix": return "Köztes pontok: " + (", ".join(session.relays) if not session.relays.is_empty() else "még csak közvetlen élek")
	if session.phase == "delivery": return "SAJÁT ÚT: " + " → ".join(session.route)
	return ""

func _state_text() -> String:
	if session.phase == "briefing": return "Mit gyakorolsz?\n" + CourierLessons.RULES[session.algorithm()] + "\n\n" + session.level["hazard"]
	if session.phase == "complete": return "A következő pálya több állomást és szűkebb keretet ad. Az új hálózat ugyanazt a szabályt gyakoroltatja más adatokon."
	if session.phase == "failed": return "A hiba nem végleges. [Z] visszaállítja az előző lépést; az újratervezés a tanult távolságokat megtartja."
	if session.algorithm() in [3,4,6]:
		var rows: Array = ["TÁVOLSÁG / ELŐD"]
		for id: String in session.graph.ids(): rows.append("%s: %s   ← %s" % [id, CourierSession.number(session.distances[id]), session.previous.get(id, "—")])
		return "\n".join(rows)
	return CourierLessons.RULES[session.algorithm()]

func _report_text() -> String:
	var names: Array[String] = ["", "Sikeres küldetés", "Biztos tudás", "Mesterfutár!"]
	var text: String = "%s\n%d XP · %d döntés · %d visszajelzés\n\n" % [names[session.result["stars"]], session.result["score"], session.turns, session.mistakes]
	if CourierLessons.is_network(session.algorithm()):
		text += "Saját hálózat: %d kredit\nMinimum: %d kredit\n\n" % [session.tree_cost, session.result["tree_minimum"]]
	elif session.algorithm() == 2:
		text += "Feladási sorrend: " + " → ".join(session.order) + "\n\n"
	else:
		for delivery: Dictionary in session.deliveries:
			text += "%s → %s: %s\nTény: %d %s · %s: %d\n\n" % [delivery["source"], delivery["target"], " → ".join(delivery["route"]), delivery["cost"], session.unit(), "BFS minimum" if session.algorithm() == 1 else "minimum", delivery["optimum"]]
	text += "AMIT MEGTANULTÁL\n" + session.result["takeaway"]
	return text

func _select(choice: String) -> void:
	if _busy:
		_update_guidance()
		return
	if _popup_open(): return
	if not _auto_dispatch: _stop_auto()
	_detail_override = ""
	_notice = "Döntésed végrehajtva"
	_notice_tone = "info"
	BureauAudio.play_cue("click")
	var event: Dictionary = session.choose(choice)
	if not event.get("accepted", false):
		_notice = "Próbáld újra — az állapotod megmaradt"
		_notice_tone = "warning"
		_detail_override = event.get("message","Ezt a lépést most nem választhatod. Válassz az elérhető gombok közül.")
		if event.get("mistake", false): _cue("feedback")
		_refresh()
		return
	if event.has("move_from") and session.algorithm() != 2:
		_travel_from = event["move_from"]
		_travel_to = event["move_to"]
		_busy = true
		_refresh()
		board.animate_packet(event["move_from"], event["move_to"])
	else:
		_refresh()

func _inspect(message: String) -> void:
	if not _busy and not _popup_open():
		_detail_override = message
		feedback_label.text = message
		_notice = "Állomás adatai megnyitva"
		_notice_tone = "info"
		_update_guidance()

func _travel_done() -> void:
	_busy = false
	_notice = "A csomag megérkezett: " + _travel_to
	_refresh()

func _undo() -> void:
	if _busy or _popup_open(): return
	_stop_auto()
	if session.undo():
		_notice = "Visszaléptél — innen újra dönthetsz"
		_notice_tone = "info"
		_detail_override = ""
		board.stop_travel()
		_refresh()

func _hint() -> void:
	if _busy or _popup_open() or session.phase in ["briefing","complete"]: return
	_stop_auto()
	session.hint()
	_notice = "Segítséget kértél — olvasd el a magyarázatot"
	_notice_tone = "info"
	_detail_override = ""
	_refresh()
	if session.phase in ["ready", "delivery"]: board.show_reference = true
	board.queue_redraw()

func _toggle_matrix() -> void:
	if session.algorithm() == 7:
		board.matrix_visible = not board.matrix_visible
		board.queue_redraw()
		_notice = "Mátrixnézet: minden feladó és címzett költsége" if board.matrix_visible else "Térképnézet: állomások és kapcsolatok"
		_notice_tone = "info"
		_update_guidance()

func _open_guide(journal: bool) -> void:
	_stop_auto()
	_notice = "A lejátszás szünetel, amíg a magyarázatot olvasod"
	_notice_tone = "info"
	_update_guidance()
	if _popup_open():
		_close_guide()
		return
	popup = PanelContainer.new()
	add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.offset_left = 100
	popup.offset_right = -100
	popup.offset_top = 105
	popup.offset_bottom = -105
	popup.add_theme_stylebox_override("panel", BureauTheme.panel(BureauTheme.SURFACE, CourierLessons.COLORS[session.algorithm()], 28))
	var column := BureauTheme.column(popup, 16)
	var top := BureauTheme.row(column)
	top.add_child(BureauTheme.label("Lépésnapló" if journal else "Miért működik? / " + CourierLessons.NAMES[session.algorithm()], 26))
	BureauTheme.spacer(top)
	var close := BureauTheme.button("Bezárás [Esc / I]")
	close.pressed.connect(_close_guide)
	top.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := BureauTheme.column(scroll, 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if journal:
		for index: int in session.logs.size(): content.add_child(BureauTheme.label("%02d  %s" % [index + 1, session.logs[index]], 17, BureauTheme.INK, true))
	else:
		content.add_child(BureauTheme.label("A FELADAT CÉLJA", 13, BureauTheme.CYAN))
		content.add_child(BureauTheme.label(CourierLessons.OBJECTIVES[session.algorithm()], 20, BureauTheme.INK, true))
		content.add_child(BureauTheme.label("A VÁLASZTÁS SZABÁLYA", 13, BureauTheme.CYAN))
		content.add_child(BureauTheme.label(CourierLessons.RULES[session.algorithm()], 20, BureauTheme.INK, true))
		for index: int in CourierLessons.PSEUDOCODE[session.algorithm()].size():
			content.add_child(BureauTheme.label("%d  %s" % [index + 1, CourierLessons.PSEUDOCODE[session.algorithm()][index]], 18, BureauTheme.GOLD, true))
		content.add_child(BureauTheme.label("A LÉNYEG", 13, BureauTheme.CYAN))
		content.add_child(BureauTheme.label(CourierLessons.TAKEAWAYS[session.algorithm()], 20, BureauTheme.INK, true))
		content.add_child(BureauTheme.label("SZOKÁSOS KOMPLEXITÁS", 13, BureauTheme.CYAN))
		content.add_child(BureauTheme.label(CourierLessons.COMPLEXITY[session.algorithm()] + ". V: állomások; E: élek. A játék látható adatstruktúrákat használ, a képletek az algoritmus szokásos megvalósítására vonatkoznak.", 17, BureauTheme.MUTED, true))
		if session.algorithm() == 6:
			content.add_child(BureauTheme.label("Itt h = légvonalbeli távolság × a legkisebb élköltség/távolság arány. A háromszög-egyenlőtlenség miatt h[u] ≤ w(u,v)+h[v], tehát a becslés konzisztens. A h=0 választás Dijkstra viselkedését adná.", 17, BureauTheme.MUTED, true))
		content.add_child(BureauTheme.label("A bevezető szinten ajánlott út is látszik. Az önálló szinteken az elődtáblából vagy a mátrixból kell következtetned. A segítség megmutathatja a következő lépést; a hibák után újra próbálkozhatsz.", 17, BureauTheme.MUTED, true))

func _popup_open() -> bool:
	return is_instance_valid(popup) and not popup.is_queued_for_deletion()

func _close_guide() -> void:
	popup.queue_free()
	_notice = "Folytathatod — ugyanott vár a feladat"
	_notice_tone = "info"
	_update_guidance()

func _home() -> void:
	board.stop_travel()
	get_tree().change_scene_to_file("res://MenuScene.tscn")

func _next() -> void:
	if _busy: return
	GameState.courier_variant = 0
	if GameState.courier_tier < 2: GameState.courier_tier += 1
	elif GameState.courier_algorithm < 8:
		GameState.courier_algorithm += 1
		GameState.courier_tier = 0
	else:
		_home()
		return
	get_tree().reload_current_scene()

func _fresh() -> void:
	if _busy: return
	GameState.courier_variant += 1
	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if _popup_open():
		if event.keycode in [KEY_ESCAPE, KEY_I, KEY_L]: _close_guide()
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_ESCAPE: _home()
		KEY_Z, KEY_BACKSPACE: _undo()
		KEY_H: _hint()
		KEY_I: _open_guide(false)
		KEY_L: _open_guide(true)
		KEY_M: _toggle_matrix()
		KEY_A: _toggle_auto()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			var index: int = event.keycode - KEY_1
			if index < _choice_ids.size(): _select(_choice_ids[index])
		KEY_ENTER, KEY_SPACE:
			if _choice_ids.size() == 1: _select(_choice_ids.front())
		_: return
	get_viewport().set_input_as_handled()

func _cue(name: String) -> void:
	BureauAudio.play_cue("complete" if name == "success" else "wrong")

func _toggle_auto() -> void:
	if _popup_open() or session.phase in ["complete", "failed", "anomaly"]: return
	if auto_play:
		_stop_auto()
		_notice = "Bemutató szüneteltetve"
	else:
		demonstration = true
		auto_play = true
		_auto_elapsed = 0
		auto_button.text = "Szünet [A]"
		_notice = "Bemutató elindult — most megmutatom a lépéseket"
	_notice_tone = "info"
	_refresh()

func _stop_auto() -> void:
	auto_play = false
	_auto_elapsed = 0
	if is_instance_valid(auto_button): auto_button.text = "Automata [A]"

func _process(delta: float) -> void:
	if not auto_play or _busy or _popup_open(): return
	_auto_elapsed += delta
	if _auto_elapsed < auto_interval: return
	_auto_elapsed = 0
	var expected: Array = session.expected_choices()
	if expected.is_empty():
		_stop_auto()
		_notice = "A bemutató megállt: nincs választható következő lépés"
		_notice_tone = "warning"
		_update_guidance()
		return
	_auto_dispatch = true
	_select(expected.front())
	_auto_dispatch = false

func _retry_save() -> void:
	_save_error = GameState.save_progress()
	_refresh()

func _update_guidance() -> void:
	var title: String = _notice if not _notice.is_empty() else "DISZPÉCSER / TE KÖVETKEZEL"
	var message: String = ""
	var next: String = ""
	var tone: String = _notice_tone
	match session.phase:
		"briefing":
			title = "Kezdjük együtt!"
			message = "Előbb megtervezzük a megoldást, aztán a saját döntéseiddel végrehajtod. Nincs időkorlát."
			next = "Olvasd el a célt és a keretet, majd kattints az Induljon a küldetés gombra."
		"search":
			message = ["A sor eleje következik; az élköltségek itt nem befolyásolják a sorrendet.","A verem teteje következik: a legutóbb betett állomást dolgozzuk fel.","","A legkisebb ismert d távolságú állomást válaszd.","","","Hasonlítsd össze az f = g + h értékeket. A legkisebb prioritás következik."][session.algorithm()]
			next = "Válassz a várakozó állomások közül a gombokon vagy a térképen. Ha elakadtál: Segítség [H]."
		"edge_check","relax":
			message = "Az új út költségét a korábbi távolsággal hasonlítjuk össze. Csak a kisebb érték javít. A ∞ azt jelenti: még nincs ismert út."
			next = "Nézd meg lent az összeadást, majd válaszd: Javítom a távolságot vagy Megtartom a régit."
		"pass_end":
			message = "Az összes aktív élt ellenőriztük ebben a körben. " + ("Volt javulás, ezért új ellenőrzőkör szükséges." if session.round_changed else "Nem volt javulás: a távolságok készen vannak.")
			next = "A folytatáshoz nyomd meg az egyetlen felajánlott gombot vagy az Entert."
		"order":
			message = "Csak olyan állomást adhatsz fel, amelynek már minden előfeltétele teljesült. Több helyes választás is lehet."
			next = "Keress 0 várakozó előfeltételű állomást, és kattints rá."
		"network":
			message = "A növekvő hálózatból kifelé vezető legolcsóbb kapcsolatot keressük." if session.algorithm() == 5 else "A legolcsóbb megmaradt élt vizsgáljuk. Külön komponenseket kötünk össze, kört nem építünk."
			next = "Válassz kapcsolatot. A költség valóban beleszámít a keretbe; visszalépéssel javíthatsz."
		"matrix":
			message = "Egy köztes állomással most minden feladó–címzett pár útját ellenőrizzük. Egy cella az adott sorból az adott oszlopba vezető költség."
			next = "Válassz köztes állomást a gombokon vagy a mátrix fejlécében. M: mátrix / térkép."
		"ready":
			title = "A terv elkészült — jöhet a kézbesítés"
			message = "Most már a tényleges útvonalról döntesz. A terv segít, de a választott sávok költsége és iránya számít."
			next = "Kattints az Átveszem a csomagot gombra."
		"delivery":
			message = "A csomag itt van: %s. A címzett: %s. A következő sávot te választod; a keretet felül követheted." % [session.route.back(),session.target()]
			next = "Kattints egy elérhető szomszédra. Az eddigi út a térképen és lent a SAJÁT ÚT sorban látszik."
		"next_package":
			title = "Az első csomag célba ért!"
			message = "A következő feladó másik állomásról indul. Ugyanazt a mátrixot használhatod; most a másik feladó sorát nézd."
			next = "A Következő csomag gombbal folytathatod."
		"failed":
			title = "Ez az út most nem sikerült — javíthatod"
			message = "A részleteket lent olvashatod. A tanult adatok megmaradtak, nem kell mindent elölről kezdened."
			next = "Visszalépés [Z]: javítsd az utolsó döntést. Újratervezem: válassz új útvonalat vagy hálózatot."
			tone = "warning"
		"anomaly":
			title = "Negatív kört találtunk"
			message = "A kör ismétlésével a költség tovább csökkenne, ezért nincs véges legrövidebb út. Ezt felismerni a feladat része."
			next = "Kattints a Jelentem a negatív kört gombra."
			tone = "warning"
		"complete":
			title = "Küldetés teljesítve!"
			if demonstration:
				message = "Végignézted a megoldást. A bemutató pont és érem nélkül segít megérteni a lépéseket."
				next = "Újra, saját döntésekkel: most már te is megoldhatod. Vagy válassz következő pályát."
			elif _save_error != OK:
				title = "Kész a küldetés, de a mentés nem sikerült"
				message = "Az eredmény most csak az alkalmazás memóriájában van. Bezárás előtt próbáld újra a mentést."
				next = "Kattints a Mentés újrapróbálása gombra."
				tone = "warning"
			else:
				message = "Eredményed mentettük ezen az eszközön. A korábbi jobb pontszámod és érmed is megmarad."
				next = "Nézd meg a jelentést, majd válassz következő pályát vagy új hálózatot."
	if _busy:
		title = "A csomag úton van: %s → %s" % [_travel_from,_travel_to]
		message = "A döntésedet végrehajtjuk. Várd meg, amíg a csomag megérkezik; közben nem kell újra kattintanod."
		next = "Az automata érkezés után magától folytatódik." if auto_play else "Érkezés után ismét választhatsz."
	elif auto_play:
		next = "Automata fut · A: szünet · a sebességet a pszeudokód mellett állíthatod."
	elif demonstration and session.phase not in ["complete","failed","anomaly"]:
		next += " Bemutató szünetel · A: folytatás. Ez a menet nem pontozott."
	guide_card.show_message(title,message,next,tone)
