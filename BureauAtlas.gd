class_name BureauAtlas
extends Control

var _time: float = 0
var _elapsed: float = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if GameState.reduced_motion: return
	_time += delta
	_elapsed += delta
	if _elapsed >= 0.05:
		_elapsed = 0
		queue_redraw()

func _draw() -> void:
	var factor: float = minf(size.x / 360, size.y / 260)
	var origin: Vector2 = (size - Vector2(360, 260) * factor) / 2
	# Draw coordinates are kept local, so resizing never changes the illustration's proportions.
	var center: Vector2 = origin + Vector2(206, 137) * factor
	BureauArt.glow(self, center, 160 * factor, BureauTheme.CYAN, 0.8)
	for ring: int in range(3):
		draw_arc(center, (65 + ring * 35) * factor, -2.7, 2.5, 96, Color(BureauTheme.CYAN, 0.1), 1, true)
	var route := PackedVector2Array()
	for index: int in range(65):
		var t: float = index / 64.0
		route.append(origin + Vector2(55 + t * 270, 155 - sin(t * PI) * 86) * factor)
	draw_polyline(route, Color(BureauTheme.CYAN, 0.09), 12 * factor, true)
	draw_polyline(route, Color(BureauTheme.CYAN, 0.7), 1.6 * factor, true)
	for index: int in [0, 16, 48, 64]:
		draw_circle(route[index], 3 * factor, BureauTheme.CYAN)
	BureauArt.planet(self, origin + Vector2(269, 155) * factor, 54 * factor, BureauTheme.CYAN)
	draw_arc(origin + Vector2(269, 155) * factor, 67 * factor, -0.4, 2.5, 64, Color(BureauTheme.CYAN, 0.45), 1.3, true)
	BureauArt.planet(self, origin + Vector2(69, 151) * factor, 28 * factor, BureauTheme.VIOLET, 1)
	BureauArt.planet(self, origin + Vector2(311, 46) * factor, 12 * factor, BureauTheme.GOLD)
	var bob: float = 0 if GameState.reduced_motion else sin(_time * 1.2) * 4
	var parcel: Vector2 = origin + Vector2(183, 84 + bob) * factor
	for streak: int in range(3):
		draw_line(parcel + Vector2(-67 - streak * 7, 7 + streak * 10) * factor, parcel + Vector2(-38 - streak * 7, 7 + streak * 10) * factor, Color(BureauTheme.GOLD, 0.5 - streak * 0.12), 2 * factor, true)
	BureauArt.envelope(self, parcel, 2.1 * factor, -0.2)
	for index: int in range(22):
		var point: Vector2 = origin + Vector2(fmod(index * 73.7 + 13, 340), fmod(index * 57.1 + 23, 218)) * factor
		draw_circle(point, factor if index % 4 else 1.7 * factor, Color(BureauTheme.INK, 0.3))
	draw_string(BureauTheme.UI_FONT, origin + Vector2(110, 233) * factor, "FELADÓ  →  CÍMZETT", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(11 * factor)), BureauTheme.MUTED)
	draw_circle(origin + Vector2(16, 20) * factor, 3 * factor, BureauTheme.CYAN)
	draw_string(BureauTheme.UI_FONT, origin + Vector2(27, 24) * factor, "POSTAHÁLÓZAT / ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(10 * factor)), BureauTheme.CYAN)
