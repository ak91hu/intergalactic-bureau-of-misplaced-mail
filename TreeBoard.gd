class_name TreeBoard
extends Control

var frame: Dictionary = {"nodes":{},"root":-1,"focus":-1,"kind":2}
var positions: Dictionary = {}
var _old_positions: Dictionary = {}
var _tween: Tween
var _blend: float = 1
var _depth: int = 1
var _radius: float = 22

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func(): _calculate_positions(); _blend = 1; queue_redraw())

func set_frame(data: Dictionary) -> void:
	_old_positions = positions.duplicate()
	frame = data.duplicate(true)
	_calculate_positions()
	if _tween: _tween.kill()
	_blend = 1 if GameState.reduced_motion else 0
	if _blend < 1:
		_tween = create_tween()
		_tween.tween_method(func(value: float): _blend = value; queue_redraw(),0.0,1.0,0.35).set_trans(Tween.TRANS_SINE)
	queue_redraw()

func _calculate_positions() -> void:
	positions.clear()
	_depth = _height(frame.get("root",-1))
	var ordered: Array = _inorder(frame.get("root",-1))
	var usable: Vector2 = size - Vector2(100,160)
	var spacing: float = minf(78, usable.y / maxi(1,_depth-1))
	_radius = clampf(spacing * 0.33, 12, 23)
	for index: int in ordered.size():
		var key: int = ordered[index]
		var depth: int = 0
		var parent: int = frame["nodes"][key]["parent"]
		while parent != -1:
			depth += 1
			parent = frame["nodes"][parent]["parent"]
		positions[key] = Vector2(50 + usable.x * (index + 0.5) / maxi(1,ordered.size()),100 + depth * spacing)

func _point(key: int) -> Vector2:
	return _old_positions.get(key, positions[key]).lerp(positions[key],_blend)

func _draw() -> void:
	draw_style_box(BureauTheme.panel(Color("0f1c32"),BureauTheme.BORDER,0),Rect2(Vector2.ZERO,size))
	BureauArt.space(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), 0, true)
	draw_line(Vector2(22, 72), Vector2(size.x - 22, 72), Color(BureauTheme.CYAN, 0.12), 1, true)
	var font: Font = BureauTheme.UI_FONT
	draw_string(font,Vector2(22,30),"IBMM / CSOMAGARCHÍVUM",HORIZONTAL_ALIGNMENT_LEFT,-1,13,BureauTheme.CYAN)
	draw_string(font,Vector2(22,57),"Balra: kisebb kulcsok    ·    Jobbra: nagyobb kulcsok",HORIZONTAL_ALIGNMENT_LEFT,-1,14,BureauTheme.MUTED)
	if positions.is_empty():
		var center := Vector2(size.x / 2, size.y / 2 - 10)
		BureauArt.glow(self, center, 105, BureauTheme.CYAN)
		for side: float in [-1.0, 1.0]:
			draw_line(center + Vector2(0, -23), center + Vector2(side * 42, 22), Color(BureauTheme.CYAN, 0.3), 2, true)
			BureauArt.planet(self, center + Vector2(side * 42, 22), 13, BureauTheme.VIOLET)
		BureauArt.envelope(self, center + Vector2(0, -23), 1.05)
		draw_string(font,Vector2(20, center.y + 76),"Az archívum üres.",HORIZONTAL_ALIGNMENT_CENTER,size.x-40,20,BureauTheme.INK)
		draw_string(font,Vector2(20, center.y + 101),"Szúrjuk be az első csomagazonosítót!",HORIZONTAL_ALIGNMENT_CENTER,size.x-40,14,BureauTheme.MUTED)
		return
	for key: int in positions:
		var node: Dictionary = frame["nodes"][key]
		for side: String in ["left","right"]:
			var child: int = node[side]
			if child != -1:
				var from: Vector2 = _point(key)
				var to: Vector2 = _point(child)
				var active: bool = key == frame.get("focus", -1) or child == frame.get("focus", -1)
				var lane_color: Color = BureauTheme.GOLD if active else Color("658499")
				draw_line(from, to, Color(lane_color, 0.07), 9, true)
				draw_line(from, to, Color(lane_color, 0.8), 2, true)
			elif frame["kind"] == 2:
				var nil_pos: Vector2 = _point(key)+Vector2(-13 if side == "left" else 13,_radius+14)
				draw_line(_point(key),nil_pos,BureauTheme.BORDER,1,true)
				draw_rect(Rect2(nil_pos-Vector2(3,3),Vector2(6,6)),Color("060a15"))
	for key: int in positions:
		var point: Vector2 = _point(key)
		var red: bool = frame["kind"] == 2 and frame["nodes"][key]["red"]
		var color: Color = Color("f27793") if red else Color("6485a7")
		if frame["kind"] != 2: color = BureauTheme.CYAN
		if key == frame.get("focus",-1):
			draw_circle(point,_radius+7,Color(BureauTheme.GOLD,0.17))
			draw_arc(point,_radius+5,0,TAU,48,BureauTheme.GOLD,2,true)
		BureauArt.planet(self, point, _radius, color, 1)
		draw_arc(point,_radius,0,TAU,48,BureauTheme.RED if red else BureauTheme.MUTED,1.5,true)
		var text: String = str(key)
		var font_size: int = 17 if _radius >= 18 else 13
		draw_string_outline(font,point+Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2,6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color("0b1726"))
		draw_string(font,point+Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2,6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,BureauTheme.INK)
		if frame["kind"] == 2 and _radius >= 18:
			draw_string(font,point+Vector2(_radius+4,4),"P" if red else "F",HORIZONTAL_ALIGNMENT_LEFT,-1,10,BureauTheme.RED if red else BureauTheme.MUTED)
	draw_string(font,Vector2(22,size.y-22),"P = piros · F = fekete · kis négyzet = fekete NIL" if frame["kind"] == 2 else "A forgatás a kulcsok sorrendjét megőrzi.",HORIZONTAL_ALIGNMENT_LEFT,-1,12,BureauTheme.MUTED)

func _height(key: int) -> int:
	if key == -1: return 0
	return 1 + maxi(_height(frame["nodes"][key]["left"]),_height(frame["nodes"][key]["right"]))

func _inorder(key: int) -> Array:
	if key == -1: return []
	return _inorder(frame["nodes"][key]["left"]) + [key] + _inorder(frame["nodes"][key]["right"])
