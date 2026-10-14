class_name MenuScene
extends Control

var _root: Control
var _grid: GridContainer
var _tree_grid: GridContainer
var _overlay: PanelContainer
var _content: VBoxContainer
var guide_card: BureauGuide

func _ready() -> void:
	BureauTheme.apply_theme(self)
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := BureauBackdrop.new()
	_root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_content = BureauTheme.column(scroll, 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := BureauTheme.row(_content)
	top.add_child(BureauTheme.label("IBMM / FUTÁRAKADÉMIA", 15, BureauTheme.CYAN))
	BureauTheme.spacer(top)
	var tree_xp: int = 0
	for score: int in GameState.tree_scores.values(): tree_xp += score
	top.add_child(BureauTheme.label("%d / 36 küldetés   ·   %d XP" % [GameState.courier_medals.size()+GameState.tree_medals.size(), GameState.courier_xp()+tree_xp], 15, BureauTheme.GOLD))
	var lab := BureauTheme.button("Algoritmuslabor")
	lab.tooltip_text = "Az eredeti kilenc algoritmus lépésenkénti vizsgálata és gyakorlása."
	lab.pressed.connect(func(): get_tree().change_scene_to_file("res://LabMenu.tscn"))
	top.add_child(lab)
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", BureauTheme.panel(Color("142a3b"), Color("375467"), 22))
	_content.add_child(hero)
	var hero_row := BureauTheme.row(hero, 20)
	var hero_text := BureauTheme.column(hero_row, 8)
	hero_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_text.add_child(BureauTheme.label("AZ INTERGALAKTIKUS POSTA VÁR RÁD", 12, BureauTheme.GOLD))
	hero_text.add_child(BureauTheme.label("A csomag útja\na te döntésed.", 36))
	hero_text.add_child(BureauTheme.label("Tanulj algoritmust. Tervezz. Kézbesíts.", 18, BureauTheme.CYAN, true))
	hero_text.add_child(BureauTheme.label("Találj utat a csillagok között, a saját tempódban.", 14, BureauTheme.MUTED, true))
	var actions := BureauTheme.row(hero_text, 10)
	var recommended: Dictionary = GameState.recommended_courier()
	var start := BureauTheme.button("Folytatás: " + CourierLessons.NAMES[recommended["algorithm"]], true)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(func(): _start_courier(recommended["algorithm"], recommended["tier"]))
	actions.add_child(start)
	var daily := BureauTheme.button("Napi küldetés")
	daily.tooltip_text = CourierLessons.NAMES[GameState.daily_algorithm()]
	daily.pressed.connect(func(): _start_courier(GameState.daily_algorithm(), 1, int(Time.get_unix_time_from_system() / 86400)))
	actions.add_child(daily)
	var illustration := BureauAtlas.new()
	illustration.name = "HeroIllustration"
	illustration.custom_minimum_size = Vector2(300, 220)
	illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.add_child(illustration)
	var steps := BureauTheme.row(_content, 20)
	for text: String in ["01  Ismerd meg a szabályt", "02  Alkosd meg a tervet", "03  Kézbesíts és értsd meg"]:
		var label := BureauTheme.label(text, 15, BureauTheme.VIOLET)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steps.add_child(label)
	guide_card = BureauGuide.new()
	_content.add_child(guide_card)
	var returning: bool = not GameState.courier_medals.is_empty() or not GameState.tree_medals.is_empty()
	guide_card.show_message("Jó újra itt — folytassuk!" if returning else "Üdv a futárakadémián! Segítek elindulni.","Válassz témát, majd nehézséget. A feladatokban mindig jelzem, mi történik és mit tehetsz következőként.","Kezdőként a Folytatás: BFS gombot ajánlom. Ha előbb megnéznéd a megoldást, a küldetésben kapcsold be az Automatát [A]." if not returning else "A Folytatás gomb a következő gráfleckét ajánlja. A fák kártyáin a korábbi érmed alapján választhatsz szintet.")
	var settings := BureauTheme.row(_content)
	settings.add_child(BureauTheme.label("HANG ÉS MEGJELENÉS", 13, BureauTheme.CYAN))
	BureauTheme.spacer(settings)
	var sound := BureauTheme.button("Effektek: be" if GameState.sound_enabled else "Effektek: ki")
	sound.pressed.connect(func(): GameState.sound_enabled = not GameState.sound_enabled; sound.text = "Effektek: be" if GameState.sound_enabled else "Effektek: ki"; _save_setting("A kattintások és visszajelzések hangja " + ("bekapcsolva." if GameState.sound_enabled else "kikapcsolva.")))
	settings.add_child(sound)
	var motion := BureauTheme.button("Mozgás: kímélő" if GameState.reduced_motion else "Mozgás: teljes")
	motion.pressed.connect(func(): GameState.reduced_motion = not GameState.reduced_motion; motion.text = "Mozgás: kímélő" if GameState.reduced_motion else "Mozgás: teljes"; _save_setting("Kímélő mozgás: a csomagok és a faállapotok animáció nélkül változnak." if GameState.reduced_motion else "Teljes mozgás: újra láthatod a csomagok útját és a forgatások mozgását."))
	settings.add_child(motion)
	var audio_settings := BureauTheme.row(_content,12)
	var music := BureauTheme.button("Zene: be" if GameState.music_enabled else "Zene: ki")
	music.pressed.connect(func(): GameState.music_enabled = not GameState.music_enabled; music.text = "Zene: be" if GameState.music_enabled else "Zene: ki"; _save_setting("A háttérzene bekapcsolva; az első kattintás után indulhat el, a csúszkával halkíthatod." if GameState.music_enabled else "A háttérzene kikapcsolva. A kattintások hangját külön kapcsolhatod."))
	audio_settings.add_child(music)
	var volume_label := BureauTheme.label("Hangerő: %d%%" % roundi(GameState.music_volume*100),14,BureauTheme.MUTED)
	audio_settings.add_child(volume_label)
	var volume := HSlider.new()
	volume.name = "MusicVolume"
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = GameState.music_volume*100
	volume.custom_minimum_size = Vector2(180,32)
	volume.tooltip_text = "Halk háttérzene hangereje"
	volume.accessibility_name = "Háttérzene hangereje"
	volume.value_changed.connect(func(value: float): GameState.music_volume = value/100; volume_label.text = "Hangerő: %d%%" % int(value); _save_setting("A háttérzene hangereje: %d%%.%s" % [int(value)," Most néma; emeld a csúszkát, ha újra hallanád." if value == 0 else (" A Zene kapcsolóval még be kell kapcsolnod." if not GameState.music_enabled else "")]))
	audio_settings.add_child(volume)
	audio_settings.add_child(BureauTheme.label("Lágy űrhangulat · külön kapcsolható kattintások",13,BureauTheme.MUTED,true))
	var section := BureauTheme.row(_content)
	section.add_child(BureauTheme.label("FEDEZD FEL AZ ALGORITMUSOKAT", 13, BureauTheme.CYAN))
	BureauTheme.spacer(section)
	section.add_child(BureauTheme.label("9 téma  /  3 nehézség", 13, BureauTheme.MUTED))
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_content.add_child(_grid)
	for algorithm: int in range(9): _card(algorithm)
	_content.add_child(BureauTheme.label("ÚJ / KERESŐFÁK ÉS EGYENSÚLYOZÁS",14,BureauTheme.CYAN))
	_content.add_child(BureauTheme.label("Rendezd a csomagazonosítókat. Értsd meg a keresést, a forgatást és a piros-fekete fa szabályait.",16,BureauTheme.MUTED,true))
	_tree_grid = GridContainer.new()
	_tree_grid.columns = 3
	_tree_grid.add_theme_constant_override("h_separation",14)
	_tree_grid.add_theme_constant_override("v_separation",14)
	_content.add_child(_tree_grid)
	for kind: int in range(3):
		var tree := BureauTheme.button("")
		tree.accessibility_name = TreeAlgorithms.NAMES[kind]
		tree.custom_minimum_size = Vector2(270, 154)
		tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var accent: Color = [BureauTheme.CYAN, BureauTheme.VIOLET, BureauTheme.RED][kind]
		BureauTheme.card(tree, accent)
		tree.pressed.connect(func(): _choose_tree(kind))
		_tree_grid.add_child(tree)
		var tree_margin := MarginContainer.new()
		tree.add_child(tree_margin)
		tree_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tree_margin.offset_left = 16
		tree_margin.offset_right = -16
		tree_margin.offset_top = 14
		tree_margin.offset_bottom = -14
		tree_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tree_body := BureauTheme.column(tree_margin, 7)
		tree_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tree_header := BureauTheme.row(tree_body, 12)
		tree_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glyph := BureauGlyph.new()
		glyph.kind = kind + 9
		glyph.accent = accent
		glyph.custom_minimum_size = Vector2(46, 46)
		tree_header.add_child(glyph)
		tree_header.add_child(BureauTheme.label("%02d / ADATSZERKEZET" % [kind + 10], 12, accent))
		tree_body.add_child(BureauTheme.label(TreeAlgorithms.NAMES[kind], 21, BureauTheme.INK, true))
		tree_body.add_child(BureauTheme.label("3 szint · beszúrás, keresés, bejárás", 13, BureauTheme.MUTED, true))
	_content.move_child(settings, _content.get_child_count() - 1)
	_content.move_child(audio_settings, _content.get_child_count() - 1)
	_content.add_child(BureauTheme.label("Mind a 12 téma elérhető, összesen 36 küldetéssel. Az automata pont nélküli bemutatóként végigmutatja a megoldást.\nZene: Floating Cities — Kevin MacLeod (incompetech.com) · CC BY 4.0 · változatlan hangfelvétel, halkítva és ismételve.\nForrás: incompetech.com/music/royalty-free/ · Licenc: creativecommons.org/licenses/by/4.0/", 12, BureauTheme.MUTED, true))
	get_viewport().size_changed.connect(_resize_cards)
	_resize_cards()

func _resize_cards() -> void:
	_grid.columns = 2 if get_viewport_rect().size.x < 1100 else 3
	_tree_grid.columns = _grid.columns

func _save_setting(message: String) -> void:
	var error: Error = GameState.save_progress()
	guide_card.show_message("Beállítás elmentve" if error == OK else "A beállítás most nem menthető",message,"Legközelebb is ezt a beállítást használjuk ezen az eszközön." if error == OK else "Most érvényes, de újraindítás után elveszhet. Később állítsd be ismét.","info" if error == OK else "warning")

func _choose_tree(kind: int) -> void:
	if is_instance_valid(_overlay): _overlay.queue_free()
	_overlay = PanelContainer.new()
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 150
	_overlay.offset_right = -150
	_overlay.offset_top = 130
	_overlay.offset_bottom = -130
	_overlay.add_theme_stylebox_override("panel",BureauTheme.panel(BureauTheme.SURFACE,BureauTheme.CYAN,26))
	var content := BureauTheme.column(_overlay,16)
	var header := BureauTheme.row(content)
	header.add_child(BureauTheme.label(TreeAlgorithms.NAMES[kind],28))
	BureauTheme.spacer(header)
	var close := BureauTheme.button("Bezárás [Esc]")
	close.pressed.connect(func(): _overlay.queue_free())
	header.add_child(close)
	content.add_child(BureauTheme.label(TreeAlgorithms.RULES[kind],18,BureauTheme.INK,true))
	for tier: int in range(3):
		var stars: int = GameState.tree_medals.get("%d:%d" % [kind,tier],0)
		var button := BureauTheme.button("%d. %s · %d kulcs · %s" % [tier+1,CourierLessons.TIERS[tier],TreeAlgorithms.sequence(tier).size(),["még nincs érem","bronz","ezüst","arany"][stars]],tier == 0)
		button.pressed.connect(func(): _start_tree(kind,tier))
		content.add_child(button)

func _start_tree(kind: int, tier: int) -> void:
	GameState.tree_kind = kind
	GameState.tree_tier = tier
	GameState.tree_variant = 0
	get_tree().change_scene_to_file("res://TreeScene.tscn")

func _card(algorithm: int) -> void:
	var button := BureauTheme.button("")
	button.custom_minimum_size = Vector2(270, 172)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	BureauTheme.card(button, CourierLessons.COLORS[algorithm])
	button.accessibility_name = CourierLessons.NAMES[algorithm] + ": " + CourierLessons.TITLES[algorithm]
	button.pressed.connect(func(): _choose_tier(algorithm))
	_grid.add_child(button)
	var margin := MarginContainer.new()
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 16
	margin.offset_top = 13
	margin.offset_right = -16
	margin.offset_bottom = -13
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := BureauTheme.column(margin, 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_header := BureauTheme.row(column, 12)
	card_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := BureauGlyph.new()
	glyph.kind = algorithm
	glyph.accent = CourierLessons.COLORS[algorithm]
	glyph.custom_minimum_size = Vector2(46, 46)
	card_header.add_child(glyph)
	card_header.add_child(BureauTheme.label("%02d / %s" % [algorithm + 1, CourierLessons.NAMES[algorithm]], 13, CourierLessons.COLORS[algorithm], true))
	column.add_child(BureauTheme.label(CourierLessons.TITLES[algorithm], 21, BureauTheme.INK, true))
	var short_goals: Array[String] = ["Sor → a legkevesebb ugrás", "Verem → mély keresés és visszalépés", "Előfeltételek → helyes feladatsorrend", "Távolságtábla → legolcsóbb út", "Relaxálás → negatív jóváírások is", "Greedy bővítés → összefüggő hálózat", "g + h → keresés a cél felé", "Mátrix → minden feladó és címzett", "Komponensek → kapcsolódás kör nélkül"]
	column.add_child(BureauTheme.label(short_goals[algorithm], 14, BureauTheme.MUTED, true))
	var progress := BureauTheme.row(column, 10)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for tier: int in range(3):
		var stars: int = GameState.courier_medals.get(CourierLessons.key(algorithm, tier), 0)
		var dot := BureauTheme.label("●", 11, BureauTheme.GOLD if stars > 0 else BureauTheme.BORDER.lightened(0.15))
		progress.add_child(dot)
		progress.add_child(BureauTheme.label("%d: %s" % [tier + 1, ["—", "Bronz", "Ezüst", "Arany"][stars]], 12, BureauTheme.GOLD if stars > 0 else BureauTheme.MUTED))

func _choose_tier(algorithm: int) -> void:
	if is_instance_valid(_overlay): _overlay.queue_free()
	_overlay = PanelContainer.new()
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 180
	_overlay.offset_right = -180
	_overlay.offset_top = 170
	_overlay.offset_bottom = -170
	_overlay.add_theme_stylebox_override("panel", BureauTheme.panel(BureauTheme.SURFACE, CourierLessons.COLORS[algorithm], 30))
	var content := BureauTheme.column(_overlay, 16)
	var header := BureauTheme.row(content)
	header.add_child(BureauTheme.label(CourierLessons.NAMES[algorithm], 30))
	BureauTheme.spacer(header)
	var close := BureauTheme.button("Bezárás [Esc]")
	close.pressed.connect(func(): _overlay.queue_free())
	header.add_child(close)
	content.add_child(BureauTheme.label(CourierLessons.OBJECTIVES[algorithm], 20, BureauTheme.INK, true))
	content.add_child(BureauTheme.label("Az algoritmust a döntéseiddel hajtod végre. Minden lépéshez látható szabály és magyarázat tartozik.", 16, BureauTheme.MUTED, true))
	for tier: int in range(3):
		var stars: int = GameState.courier_medals.get(CourierLessons.key(algorithm, tier), 0)
		var label: String = "%d. %s  ·  %d állomás%s" % [tier + 1, CourierLessons.TIERS[tier], 6 + tier, " · lezárt sáv" if tier > 0 else " · vezetett első kézbesítés"]
		var button := BureauTheme.button(label, tier == 0)
		button.tooltip_text = "Legjobb eredmény: " + ["még nincs", "bronz", "ezüst", "arany"][stars]
		button.pressed.connect(func(): _start_courier(algorithm, tier))
		content.add_child(button)

func _start_courier(algorithm: int, tier: int, variant: int = 0) -> void:
	GameState.courier_algorithm = algorithm
	GameState.courier_tier = tier
	GameState.courier_variant = variant
	get_tree().change_scene_to_file("res://CourierScene.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_instance_valid(_overlay):
		_overlay.queue_free()
