extends Node
## Tiny procedural sound bank: every effect is a synthesised 16-bit WAV built
## at startup, so no audio files are needed.

const RATE := 22050
const VOICES := 14

var _bank: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	_bank["shoot"] = _make(0.09, func(t, u): return _square(t, lerpf(900.0, 520.0, u)) * 0.22 * (1.0 - u))
	_bank["hit"] = _make(0.07, func(t, u): return _noise(t) * 0.20 * (1.0 - u))
	var boom := func(t, u): return (_noise(t) * 0.7 + _sine(t, lerpf(220.0, 45.0, u)) * 0.5) * 0.42 * pow(1.0 - u, 1.6)
	_bank["boom"] = _make(0.45, boom)
	var bigboom := func(t, u): return (_noise(t) * 0.8 + _sine(t, lerpf(160.0, 30.0, u)) * 0.6) * 0.5 * pow(1.0 - u, 1.3)
	_bank["bigboom"] = _make(0.9, bigboom)
	_bank["pickup"] = _make(0.18, func(t, u): return _square(t, lerpf(520.0, 1180.0, u)) * 0.20 * (1.0 - u * 0.5))
	_bank["ehit"] = _make(0.22, func(t, u): return (_noise(t) * 0.5 + _square(t, lerpf(380.0, 90.0, u))) * 0.28 * (1.0 - u))
	_bank["warn"] = _make(0.5, func(t, u): return _square(t, 320.0 + 120.0 * sin(t * 28.0)) * 0.16 * (1.0 - u * 0.4))

	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var s: AudioStream = _bank.get(name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# --- synthesis --------------------------------------------------------------

func _sine(t: float, f: float) -> float:
	return sin(TAU * f * t)


func _square(t: float, f: float) -> float:
	return 1.0 if fmod(t * f, 1.0) < 0.5 else -1.0


func _noise(t: float) -> float:
	# cheap deterministic hash noise
	var n := sin(t * 12543.7) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0


func _make(duration: float, voice: Callable) -> AudioStreamWAV:
	var count := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var u := float(i) / float(count)
		var v: float = clampf(voice.call(t, u), -1.0, 1.0)
		# short fade-out to avoid clicks
		v *= clampf((1.0 - u) * 12.0, 0.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
