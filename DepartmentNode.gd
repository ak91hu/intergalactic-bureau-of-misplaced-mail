class_name DepartmentNode
extends Node2D

const NODE_WIDTH: float = 184.0
const NODE_HEIGHT: float = 72.0
const SHORT_NAMES := {"redundancy": "COMMAND HQ", "forms": "FORMS BUREAU", "delays": "DELAY OFFICE", "stamps": "RUBBER STAMPS", "lost": "LOST ARCHIVES", "destination": "MAIL DELIVERY"}
var department_id: String = ""
var department_name: String = ""
var visual_state: String = "default"
var selectable: bool = false
var hovered: bool = false
var _time: float = 0.0

func setup(id: String, title: String) -> void:
	department_id = id
	department_name = title
	queue_redraw()

func set_visual_state(state: String) -> void:
	visual_state = state
	queue_redraw()

func get_visual_state() -> String:
	return visual_state

func _process(delta: float) -> void:
	_time += delta
	if visual_state == "frontier" and not GameState.reduced_motion:
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(-NODE_WIDTH / 2, -NODE_HEIGHT / 2, NODE_WIDTH, NODE_HEIGHT)
	var accent: Color = BureauTheme.BORDER
	var fill: Color = BureauTheme.SURFACE
	var status: String = "WAITING"
	if visual_state == "frontier":
		accent = BureauTheme.GOLD
		fill = Color("332b26")
		status = "IN FRONTIER"
	elif visual_state == "visited":
		accent = BureauTheme.CYAN
		fill = Color("142b32")
		status = "PROCESSED"
	if selectable:
		accent = BureauTheme.VIOLET
		status = "CLICK TO CHOOSE"
	if hovered:
		accent = BureauTheme.INK
	var style := BureauTheme.panel(fill, accent, 0)
	style.set_border_width_all(2 if selectable or hovered else 1)
	if visual_state == "frontier" and not GameState.reduced_motion:
		style.shadow_color = Color(accent, 0.17)
		style.shadow_size = 8 + int(3 * sin(_time * 3))
	style.draw(get_canvas_item(), rect)
	draw_line(Vector2(-78, -20), Vector2(-78, 20), accent, 3, true)
	draw_circle(Vector2(72, -23), 2.5, accent if accent != BureauTheme.BORDER else BureauTheme.MUTED)
	draw_string(BureauTheme.UI_FONT, Vector2(-65, -8), SHORT_NAMES.get(department_id, department_id), HORIZONTAL_ALIGNMENT_CENTER, 135, 14, BureauTheme.INK)
	draw_string(BureauTheme.UI_FONT, Vector2(-65, 18), status, HORIZONTAL_ALIGNMENT_CENTER, 135, 10, accent if accent != BureauTheme.BORDER else BureauTheme.MUTED)
