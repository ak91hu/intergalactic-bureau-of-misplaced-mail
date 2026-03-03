class_name DepartmentNode
extends Node2D

const NODE_WIDTH:   float = 190.0
const NODE_HEIGHT:  float = 64.0
const BADGE_HEIGHT: float = 16.0
const FONT_SIZE:    int   = 11
const RADIUS_NODE:  int   = 10

# Galaxy palette
const M_OUTLINE:   Color = Color(0.20, 0.16, 0.38)
const M_TERTIARY:  Color = Color(1.00, 0.72, 0.12)
const M_PRIMARY_C: Color = Color(0.15, 0.09, 0.36)
const M_ON_SURF:   Color = Color(0.93, 0.90, 1.00)

var department_id:   String = ""
var department_name: String = ""
var visual_state:    String = "default"
var _current_state:  String = "default"

var _panel_style: StyleBoxFlat = null
var _badge_style: StyleBoxFlat = null
var _glow_style:  StyleBoxFlat = null
var _show_glow:   bool         = false
var _glow_size:   float        = 16.0
var _glow_tween:  Tween        = null


func setup(dept_id: String, dept_name: String) -> void:
	department_id   = dept_id
	department_name = dept_name
	_rebuild_styles()
	queue_redraw()


func set_visual_state(new_state: String) -> void:
	if visual_state == new_state:
		return
	visual_state   = new_state
	_current_state = new_state

	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null

	if new_state == "frontier":
		_glow_tween = create_tween()
		_glow_tween.set_loops()
		_glow_tween.tween_method(Callable(self, "_set_glow_size"), 10.0, 24.0, 0.8).set_ease(Tween.EASE_IN_OUT)
		_glow_tween.tween_method(Callable(self, "_set_glow_size"), 24.0, 10.0, 0.8).set_ease(Tween.EASE_IN_OUT)
	else:
		_glow_size = 16.0

	_rebuild_styles()
	queue_redraw()


func _set_glow_size(size: float) -> void:
	_glow_size = size
	queue_redraw()


func get_visual_state() -> String:
	return _current_state


func _rebuild_styles() -> void:
	_panel_style = StyleBoxFlat.new()
	_badge_style = StyleBoxFlat.new()
	_glow_style  = StyleBoxFlat.new()

	match visual_state:
		"frontier":
			_panel_style.bg_color     = Color(0.28, 0.20, 0.04)
			_panel_style.border_color = M_TERTIARY
			_badge_style.bg_color     = Color(0.50, 0.34, 0.02)
			_show_glow                = true
		"visited":
			_panel_style.bg_color     = Color(0.09, 0.08, 0.14)
			_panel_style.border_color = Color(0.18, 0.15, 0.30)
			_badge_style.bg_color     = Color(0.12, 0.10, 0.20)
			_show_glow                = false
		_: # "default"
			_panel_style.bg_color     = Color(0.07, 0.05, 0.13)
			_panel_style.border_color = M_OUTLINE
			_badge_style.bg_color     = M_PRIMARY_C
			_show_glow                = false

	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(RADIUS_NODE)
	_panel_style.shadow_color = Color(0.00, 0.00, 0.08, 0.55)
	_panel_style.shadow_size  = 6
	_panel_style.set_content_margin_all(0)

	_badge_style.set_border_width_all(0)
	_badge_style.corner_radius_top_left     = RADIUS_NODE
	_badge_style.corner_radius_top_right    = RADIUS_NODE
	_badge_style.corner_radius_bottom_left  = 0
	_badge_style.corner_radius_bottom_right = 0
	_badge_style.set_content_margin_all(0)

	_glow_style.bg_color     = Color(0, 0, 0, 0)
	_glow_style.set_border_width_all(0)
	_glow_style.set_corner_radius_all(RADIUS_NODE)
	_glow_style.shadow_color = M_TERTIARY
	_glow_style.shadow_size  = 16
	_glow_style.set_content_margin_all(0)


func _draw() -> void:
	var card_rect  := Rect2(Vector2(-95, -32), Vector2(190, 64))
	var badge_rect := Rect2(Vector2(-95, -32), Vector2(190, BADGE_HEIGHT))

	if _show_glow and _glow_style:
		_glow_style.shadow_size = int(_glow_size)
		var glow_rect := Rect2(card_rect.position - Vector2(5, 5),
				card_rect.size + Vector2(10, 10))
		_glow_style.draw(get_canvas_item(), glow_rect)

	if _panel_style:
		_panel_style.draw(get_canvas_item(), card_rect)

	if _badge_style:
		_badge_style.draw(get_canvas_item(), badge_rect)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-89, -32 + BADGE_HEIGHT - 4),
		department_id.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		178, 9, M_ON_SURF
	)

	draw_multiline_string(
		ThemeDB.fallback_font,
		Vector2(-87, -32 + BADGE_HEIGHT + FONT_SIZE),
		department_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		174, FONT_SIZE, 3, M_ON_SURF
	)
