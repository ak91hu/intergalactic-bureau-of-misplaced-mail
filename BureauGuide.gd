class_name BureauGuide
extends PanelContainer

var heading: Label
var message: Label
var next_action: Label
var _styles: Dictionary = {}
var _tone: String = ""

func _init() -> void:
	accessibility_name = "Diszpécser: útmutatás és következő lépés"
	var body := BureauTheme.column(self,5)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading = BureauTheme.label("DISZPÉCSER",12,BureauTheme.CYAN,true)
	body.add_child(heading)
	message = BureauTheme.label("",15,BureauTheme.INK,true)
	body.add_child(message)
	next_action = BureauTheme.label("",13,BureauTheme.MUTED,true)
	body.add_child(next_action)

func show_message(title: String, text: String, next_text: String = "", tone: String = "info") -> void:
	var accent: Color = BureauTheme.RED if tone == "error" else (BureauTheme.GOLD if tone == "warning" else BureauTheme.CYAN)
	if _tone != tone:
		if not _styles.has(tone): _styles[tone] = BureauTheme.panel(Color("15263a"),accent.darkened(0.45),12)
		add_theme_stylebox_override("panel",_styles[tone])
		_tone = tone
	heading.text = title
	heading.add_theme_color_override("font_color",accent)
	message.text = text
	next_action.text = next_text
	next_action.visible = not next_text.is_empty()
