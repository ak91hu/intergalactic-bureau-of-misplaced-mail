class_name BureauBackdrop
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
	if _elapsed >= 0.1:
		_elapsed = 0
		queue_redraw()

func _draw() -> void:
	BureauArt.space(self, Rect2(Vector2.ZERO, size), _time)
