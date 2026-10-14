class_name BureauGlyph
extends Control

var kind: int = 0
var accent: Color = BureauTheme.CYAN

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var origin: Vector2 = size / 2 - Vector2(18, 18)
	var style := BureauTheme.panel(Color(accent, 0.09), Color(accent, 0.15), 0)
	style.set_corner_radius_all(10)
	draw_style_box(style, Rect2(origin - Vector2(5, 5), Vector2(46, 46)))
	var points: Array[Vector2] = [Vector2(18, 6), Vector2(6, 19), Vector2(30, 19), Vector2(12, 31)]
	if kind in [2, 5, 8, 9, 10, 11]: points[3] = Vector2(30, 31)
	if kind == 1: points = [Vector2(9, 6), Vector2(27, 14), Vector2(9, 23), Vector2(27, 31)]
	if kind == 2: points = [Vector2(5, 18), Vector2(14, 18), Vector2(23, 18), Vector2(32, 18)]
	if kind == 7:
		for index: int in range(3):
			for row: int in range(3):
				draw_rect(Rect2(origin + Vector2(6 + index * 10, 6 + row * 10), Vector2(5, 5)), Color(accent, 0.85 if index == row else 0.3))
		return
	var connections: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3)]
	if kind in [1, 2]: connections = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3)]
	for pair: Vector2i in connections:
		draw_line(origin + points[pair.x], origin + points[pair.y], Color(accent, 0.65), 1.4, true)
	if kind in [3, 4, 6, 7]: draw_line(origin + points[2], origin + points[3], Color(accent, 0.35), 1, true)
	for index: int in points.size():
		draw_circle(origin + points[index], 3.5, accent if index == 0 else accent.darkened(0.5))
		draw_arc(origin + points[index], 3.5, 0, TAU, 16, accent, 1, true)
