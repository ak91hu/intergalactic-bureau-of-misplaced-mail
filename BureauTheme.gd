class_name BureauTheme
extends RefCounted

const UI_FONT: Font = preload("res://assets/Inter.ttf")

const BG := Color("080e1c")
const SURFACE := Color("101d30")
const RAISED := Color("1a2c42")
const BORDER := Color("30455e")
const INK := Color("eff4ff")
const MUTED := Color("a6b7d1")
const CYAN := Color("66efd2")
const VIOLET := Color("ac97ff")
const GOLD := Color("ffc876")
const RED := Color("ff99ac")

static func panel(color: Color = SURFACE, border: Color = BORDER, padding: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(padding)
	style.corner_detail = 12
	if padding > 0:
		style.shadow_color = Color(0.015, 0.025, 0.055, 0.22)
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 4)
	return style

static func apply_theme(root: Control) -> void:
	var theme := Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 15
	for type: String in ["OptionButton", "PopupMenu"]:
		theme.set_color("font_color", type, INK)
		theme.set_stylebox("normal" if type == "OptionButton" else "panel", type, panel(RAISED, BORDER, 10))
		theme.set_stylebox("hover", type, panel(Color("243e55"), CYAN.darkened(0.4), 10))
		theme.set_stylebox("pressed", type, panel(SURFACE, CYAN, 10))
		theme.set_stylebox("focus", type, panel(Color(0, 0, 0, 0), GOLD, 10))
	var track := panel(Color("142337"), Color("142337"), 0)
	var grabber := panel(Color("49677b"), Color("49677b"), 0)
	var blank_icon := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	track.set_corner_radius_all(4)
	grabber.set_corner_radius_all(4)
	for type: String in ["VScrollBar", "HScrollBar"]:
		var scroll_track: StyleBoxFlat = track.duplicate()
		var thumb: StyleBoxFlat = grabber.duplicate()
		var highlight := panel(CYAN.darkened(0.4), CYAN.darkened(0.4), 0)
		var pressed := panel(CYAN, CYAN, 0)
		for style: StyleBoxFlat in [scroll_track, thumb, highlight, pressed]:
			style.set_content_margin(SIDE_LEFT if type == "VScrollBar" else SIDE_TOP, 4)
			style.set_content_margin(SIDE_RIGHT if type == "VScrollBar" else SIDE_BOTTOM, 4)
		theme.set_stylebox("scroll", type, scroll_track)
		theme.set_stylebox("grabber", type, thumb)
		theme.set_stylebox("grabber_highlight", type, highlight)
		theme.set_stylebox("grabber_pressed", type, pressed)
		theme.set_icon("increment", type, blank_icon)
		theme.set_icon("decrement", type, blank_icon)
	root.theme = theme

static func card(item: Button, accent: Color) -> void:
	item.add_theme_stylebox_override("normal", panel(SURFACE.lerp(accent, 0.035), BORDER.lerp(accent, 0.16), 12))
	item.add_theme_stylebox_override("hover", panel(RAISED.lerp(accent, 0.09), accent.darkened(0.2), 12))
	item.add_theme_stylebox_override("pressed", panel(SURFACE.lerp(accent, 0.13), accent, 12))

static func label(text: String, font_size: int = 16, color: Color = INK, wrap: bool = false) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_override("font", UI_FONT)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

static func button(text: String, primary: bool = false) -> Button:
	var item := Button.new()
	item.text = text
	item.add_theme_font_override("font", UI_FONT)
	item.custom_minimum_size.y = 44
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_font_size_override("font_size", 16)
	item.add_theme_color_override("font_color", BG if primary else INK)
	item.add_theme_color_override("font_hover_color", BG if primary else INK)
	item.add_theme_color_override("font_pressed_color", BG if primary else INK)
	item.add_theme_color_override("font_disabled_color", Color("75879c"))
	item.add_theme_stylebox_override("normal", panel(CYAN if primary else RAISED, CYAN if primary else BORDER, 12))
	item.add_theme_stylebox_override("hover", panel(Color("a0ffe7") if primary else Color("253e54"), CYAN, 12))
	item.add_theme_stylebox_override("pressed", panel(GOLD if primary else SURFACE, GOLD, 12))
	item.add_theme_stylebox_override("disabled", panel(SURFACE, BORDER, 12))
	var focus := panel(Color(0, 0, 0, 0), GOLD, 12)
	focus.set_border_width_all(2)
	item.add_theme_stylebox_override("focus", focus)
	return item

static func column(parent: Node, separation: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

static func row(parent: Node, separation: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

static func spacer(parent: Node) -> Control:
	var item := Control.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(item)
	return item
