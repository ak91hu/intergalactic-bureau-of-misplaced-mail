extends Node

var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var cues: Dictionary = {}
var _unlocked: bool = false
var _last_click: int = -1000

func _ready() -> void:
	music = AudioStreamPlayer.new()
	var track: AudioStreamMP3 = load("res://assets/FloatingCities.mp3")
	track = track.duplicate()
	track.loop = true
	music.stream = track
	music.volume_db = -60
	add_child(music)
	effects = AudioStreamPlayer.new()
	effects.volume_db = -17
	effects.max_polyphony = 4
	add_child(effects)
	get_tree().node_added.connect(_attach_button)
	_unlocked = OS.get_name() != "Web" and DisplayServer.get_name() != "headless"
	for cue: String in ["click", "correct", "wrong", "complete"]:
		cues[cue] = _soft_tone(cue)

func _attach_button(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_cue.bind("click"))

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch) and event.is_pressed():
		_unlocked = true

func _process(delta: float) -> void:
	var enabled: bool = GameState.music_enabled and GameState.music_volume > 0 and _unlocked
	var target: float = linear_to_db(GameState.music_volume) - 18 if enabled else -60.0
	music.volume_db = move_toward(music.volume_db, target, delta * 24)
	if enabled and not music.playing:
		music.play()
	elif not enabled and music.volume_db <= -59.9 and music.playing:
		music.stop()

func play_cue(cue: String = "click") -> void:
	if not GameState.sound_enabled: return
	if cue == "click":
		var now: int = Time.get_ticks_msec()
		if now - _last_click < 60: return
		_last_click = now
	effects.stream = cues.get(cue, cues["click"])
	effects.play()

func _soft_tone(cue: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var duration: float = {"click":0.065,"correct":0.16,"wrong":0.18,"complete":0.4}[cue]
	var count: int = int(22050 * duration)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index: int in count:
		var time: float = index / 22050.0
		var progress: float = float(index) / (count - 1)
		var envelope: float = pow(sin(PI * progress), 2) * exp(-progress * 2)
		var frequency: float = {"click":620.0,"correct":523.25,"wrong":261.63,"complete":392.0}[cue]
		var wave: float = sin(TAU * frequency * time) * 0.75 + sin(TAU * frequency * 1.5 * time) * 0.25
		if cue == "complete": wave = (sin(TAU * 392 * time) + sin(TAU * 493.88 * time) + sin(TAU * 587.33 * time)) / 3
		samples.encode_s16(index * 2, int(wave * envelope * 11000))
	stream.data = samples
	return stream
