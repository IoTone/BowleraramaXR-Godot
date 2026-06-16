# MusicDirector (autoload): generates endless synthwave in-engine — no audio
# assets. A small software synth (bass + arpeggio + pad + drums) runs over
# randomized minor-key progressions and feeds an AudioStreamGenerator.
#
# Perf note: per-sample synthesis at 22 kHz in GDScript is fine on desktop and
# modest on standalone XR; if it ever stutters on-device, move _next_sample()
# generation onto a thread that fills bars ahead of time.
extends Node

const RATE := 22050
const BPM := 100.0
const MASTER_DB := -7.0

# Progressions as [root_midi, is_minor], one chord per bar, all in A-minor land.
const PROGRESSIONS := [
	[[45, true], [41, false], [48, false], [43, false]],   # Am  F  C  G
	[[45, true], [43, false], [41, false], [40, false]],   # Am  G  F  E
	[[50, true], [45, true], [46, false], [41, false]],    # Dm  Am Bb F
	[[45, true], [48, false], [41, false], [43, false]],   # Am  C  F  G
]
const ARP_PATTERNS := [
	[0, 1, 2, 3, 2, 1, 2, 3],
	[0, 2, 1, 3, 0, 2, 3, 2],
	[3, 2, 1, 0, 1, 2, 3, 2],
	[0, 1, 2, 1, 3, 2, 1, 2],
]

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

var _sample := 0
var _sp16 := 0.0
var _last_step := -1

var _prog := []
var _arp_pattern := []
var _bar := -1
var _chord_root := 45
var _chord_minor := true

# Oscillator phases.
var _ph_bass := 0.0
var _ph_arp := 0.0
var _ph_pad := [0.0, 0.0, 0.0]
var _ph_kick := 0.0

# Envelopes / triggers.
var _bass_amp := 0.0
var _bass_freq := 110.0
var _arp_amp := 0.0
var _arp_freq := 440.0
var _arp_idx := -1
var _kick_amp := 0.0
var _kick_freq := 80.0
var _snare_amp := 0.0
var _hat_amp := 0.0
var _pad_freq := [220.0, 261.0, 329.0]

# Echo line for the arp.
var _delay := PackedFloat32Array()
var _delay_pos := 0

func _ready() -> void:
	randomize()
	_sp16 = RATE * 60.0 / BPM / 4.0
	_delay.resize(int(RATE * 0.33))
	_pick_progression()

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.25
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = MASTER_DB
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	_fill()

func _process(_delta: float) -> void:
	_fill()

func _fill() -> void:
	if _playback == null:
		return
	var n := _playback.get_frames_available()
	for i in n:
		_playback.push_frame(_next_sample())

func _pick_progression() -> void:
	_prog = PROGRESSIONS[randi() % PROGRESSIONS.size()]
	_arp_pattern = ARP_PATTERNS[randi() % ARP_PATTERNS.size()]

func _midi_to_freq(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)

func _chord_tone(i: int) -> int:
	var third := _chord_root + (3 if _chord_minor else 4)
	match i:
		0: return _chord_root
		1: return third
		2: return _chord_root + 7
		_: return _chord_root + 12

# Advance the sequencer at each 16th-note boundary.
func _on_step(global_step: int) -> void:
	var s16 := global_step % 16
	if s16 == 0:
		_bar += 1
		var chord: Array = _prog[_bar % _prog.size()]
		_chord_root = chord[0]
		_chord_minor = chord[1]
		_pad_freq = [
			_midi_to_freq(_chord_tone(0) + 12),
			_midi_to_freq(_chord_tone(1) + 12),
			_midi_to_freq(_chord_tone(2) + 12),
		]
		if _bar % 8 == 0:
			_pick_progression()
	# Drums: four-on-the-floor kick, backbeat snare, 8th-note hats.
	if s16 % 4 == 0:
		_kick_amp = 1.0
		_kick_freq = 90.0
		_bass_amp = 1.0
		_bass_freq = _midi_to_freq(_chord_root - 12)
	if s16 == 4 or s16 == 12:
		_snare_amp = 1.0
	if s16 % 2 == 0:
		_hat_amp = 0.6
	# Arp: a new chord tone every 16th.
	_arp_idx = (_arp_idx + 1) % _arp_pattern.size()
	_arp_amp = 0.9
	_arp_freq = _midi_to_freq(_chord_tone(_arp_pattern[_arp_idx]) + 24)

func _next_sample() -> Vector2:
	var step := int(_sample / _sp16)
	if step != _last_step:
		_last_step = step
		_on_step(step)
	_sample += 1

	# Bass: saw with per-beat pluck decay.
	_ph_bass = fmod(_ph_bass + _bass_freq / RATE, 1.0)
	var bass := (2.0 * _ph_bass - 1.0) * _bass_amp
	_bass_amp *= 0.99955

	# Arp: detuned saw, short decay, fed through the echo.
	_ph_arp = fmod(_ph_arp + _arp_freq / RATE, 1.0)
	var arp_dry := (2.0 * _ph_arp - 1.0) * _arp_amp
	_arp_amp *= 0.9990
	var echo := _delay[_delay_pos]
	var arp := arp_dry + echo * 0.45
	_delay[_delay_pos] = arp_dry + echo * 0.35
	_delay_pos = (_delay_pos + 1) % _delay.size()

	# Pad: soft sustained triad.
	var pad := 0.0
	for k in 3:
		_ph_pad[k] = fmod(_ph_pad[k] + _pad_freq[k] / RATE, 1.0)
		pad += sin(TAU * _ph_pad[k])
	pad *= 0.10

	# Drums.
	_ph_kick = fmod(_ph_kick + _kick_freq / RATE, 1.0)
	var kick := sin(TAU * _ph_kick) * _kick_amp
	_kick_amp *= 0.9990
	_kick_freq = lerpf(45.0, _kick_freq, 0.9994)
	var snare := (randf() * 2.0 - 1.0) * _snare_amp
	_snare_amp *= 0.9985
	var hat := (randf() * 2.0 - 1.0) * _hat_amp
	_hat_amp *= 0.992

	var mix := bass * 0.45 + arp * 0.32 + pad + kick * 0.7 + snare * 0.28 + hat * 0.10
	var s := tanh(mix * 0.8)
	# Slight stereo width from the echo on one side.
	return Vector2(s, tanh((mix + echo * 0.15) * 0.8))
