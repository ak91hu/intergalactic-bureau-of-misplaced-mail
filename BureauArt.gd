class_name BureauArt
extends RefCounted

# Original vector artwork, shared by every scene. No downloaded art or shaders.
static var _gradients: Dictionary = {}

static func _gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var key: String = top.to_html() + bottom.to_html()
	if not _gradients.has(key):
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([top, bottom])
		var texture := GradientTexture2D.new()
		texture.gradient = ramp
		texture.width = 128
		texture.height = 256
		texture.fill_from = Vector2.ZERO
		texture.fill_to = Vector2(0.8, 1)
		_gradients[key] = texture
	return _gradients[key]

static func glow(canvas: CanvasItem, point: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	for ring: int in range(10, 0, -1):
		canvas.draw_circle(point, radius * ring / 10.0, Color(color, 0.009 * strength))

static func space(canvas: CanvasItem, rect: Rect2, time: float = 0, grid: bool = false) -> void:
	var texture: GradientTexture2D = _gradient(Color("132e42") if grid else Color("14243b"), BureauTheme.BG)
	if grid:
		var vertices := PackedVector2Array()
		var uvs := PackedVector2Array()
		var radius: float = 13
		var centers: Array[Vector2] = [rect.position + Vector2(radius, radius), Vector2(rect.end.x - radius, rect.position.y + radius), rect.end - Vector2(radius, radius), Vector2(rect.position.x + radius, rect.end.y - radius)]
		for corner: int in range(4):
			for step: int in range(9):
				var angle: float = PI + corner * PI / 2 + step * PI / 16
				var point: Vector2 = centers[corner] + Vector2(cos(angle), sin(angle)) * radius
				vertices.append(point)
				uvs.append((point - rect.position) / rect.size)
		canvas.draw_polygon(vertices, PackedColorArray([Color.WHITE]), uvs, texture)
	else:
		canvas.draw_texture_rect(texture, rect, false)
	glow(canvas, rect.position + rect.size * Vector2(0.88, 0.24), rect.size.x * 0.4, BureauTheme.CYAN, 0.6)
	glow(canvas, rect.position + rect.size * Vector2(0.12, 0.8), rect.size.x * 0.33, BureauTheme.VIOLET, 0.5)
	if grid:
		for x: int in range(32, int(rect.size.x) - 16, 40):
			for y: int in range(84, int(rect.size.y) - 38, 40):
				canvas.draw_circle(rect.position + Vector2(x, y), 0.65, Color(BureauTheme.CYAN, 0.12))
		var center: Vector2 = rect.position + rect.size * Vector2(0.5, 0.52)
		for ring: int in range(1, 4):
			canvas.draw_arc(center, rect.size.y * ring * 0.19, 0, TAU, 96, Color(BureauTheme.CYAN, 0.032), 1, true)
	for index: int in range(95):
		var point: Vector2 = rect.position + Vector2(fmod(index * 137.31 + 29, maxf(1, rect.size.x)), fmod(index * 93.77 + 17, maxf(1, rect.size.y)))
		var opacity: float = 0.14 + 0.06 * sin(time * 0.5 + index)
		canvas.draw_circle(point, 1.5 if index % 13 == 0 else 0.7, Color(BureauTheme.INK, opacity))
		if index % 23 == 0:
			canvas.draw_line(point - Vector2(3, 0), point + Vector2(3, 0), Color(BureauTheme.CYAN, opacity * 0.8), 1, true)
			canvas.draw_line(point - Vector2(0, 3), point + Vector2(0, 3), Color(BureauTheme.CYAN, opacity * 0.8), 1, true)

static func planet(canvas: CanvasItem, center: Vector2, radius: float, color: Color, variant: int = 0) -> void:
	canvas.draw_circle(center + Vector2(0, radius * 0.15), radius + 2, Color(0, 0, 0, 0.25))
	glow(canvas, center, radius * 1.55, color, 1.4)
	canvas.draw_circle(center, radius, color.darkened(0.78))
	for band: int in range(36):
		var t: float = band / 36.0
		canvas.draw_circle(center + Vector2(-0.17, -0.2) * radius * t, radius * (1.0 - t * 0.62), color.darkened(0.7 - t * 0.43))
	canvas.draw_arc(center, radius, 0, TAU, 64, Color(color, 0.48), 1.25, true)
	canvas.draw_arc(center - Vector2(0.1, 0.12) * radius, radius * 0.8, -2.9, -1.05, 28, Color(color.lightened(0.4), 0.4), 2, true)
	if variant % 2 == 0:
		canvas.draw_arc(center + Vector2(-0.24, -0.14) * radius, radius * 0.51, -1.9, 0.5, 24, Color(color, 0.28), radius * 0.11, true)
		canvas.draw_arc(center + Vector2(0.25, 0.17) * radius, radius * 0.39, 0.9, 3.2, 24, Color(color, 0.19), radius * 0.13, true)
	else:
		canvas.draw_arc(center, radius * 0.83, 0.2, 2.7, 32, Color(color, 0.22), radius * 0.09, true)

static func envelope(canvas: CanvasItem, point: Vector2, scale: float = 1.0, angle: float = 0.0) -> void:
	glow(canvas, point, 30 * scale, BureauTheme.GOLD, 1.3)
	canvas.draw_set_transform(point, angle, Vector2.ONE * scale)
	var shadow := BureauTheme.panel(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 0)
	shadow.set_corner_radius_all(4)
	canvas.draw_style_box(shadow, Rect2(-16, -8, 34, 24))
	var body := BureauTheme.panel(Color("ffe1a8"), BureauTheme.GOLD, 0)
	body.set_corner_radius_all(4)
	canvas.draw_style_box(body, Rect2(-17, -12, 34, 24))
	canvas.draw_line(Vector2(-15, 9), Vector2(0, -2), Color("d89b59"), 1.1, true)
	canvas.draw_line(Vector2(15, 9), Vector2(0, -2), Color("d89b59"), 1.1, true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16, -10), Vector2(16, -10), Vector2(0, 2)]), Color("fff0cf"))
	canvas.draw_polyline(PackedVector2Array([Vector2(-16, -10), Vector2(0, 2), Vector2(16, -10)]), Color("d89b59"), 1.2, true)
	canvas.draw_circle(Vector2(0, 2), 2.8, Color("d47c51"))
	canvas.draw_set_transform(Vector2.ZERO)
