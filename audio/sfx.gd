# Sfx (autoload): procedurally-synthesized impact sound bank. No audio assets —
# each one-shot is a short decaying impact buffer generated at startup, then
# played via transient AudioStreamPlayer3D nodes at the contact point.
extends Node

const RATE := 44100

var _bank: Dictionary = {}

func _ready() -> void:
	# name -> AudioStreamWAV   (freq, decay, noise, dur, brightness)
	_bank["ball_touch"] = _make_impact(115.0, 20.0, 0.35, 0.18, 0.2)   # ball meets lane
	_bank["ball_hit"]   = _make_impact(170.0, 14.0, 0.5, 0.16, 0.5)    # ball strikes pin
	_bank["pin_hit"]    = _make_impact(320.0, 24.0, 0.4, 0.13, 0.9)    # pin clacks pin/lane

## Play a one-shot at a world position. impact (0..1+) scales volume & pitch.
func play(sound: String, pos: Vector3, impact: float = 1.0) -> void:
	var stream: AudioStreamWAV = _bank.get(sound)
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.max_db = 0.0
	p.volume_db = lerpf(-18.0, 3.0, clampf(impact, 0.0, 1.5) / 1.5)
	p.pitch_scale = randf_range(0.92, 1.12) * (0.9 + 0.2 * clampf(impact, 0.0, 1.0))
	p.unit_size = 4.0
	var root := get_tree().current_scene
	if root == null:
		return
	root.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()

## Synthesize a short percussive impact as a 16-bit mono PCM stream.
func _make_impact(freq: float, decay: float, noise: float, dur: float, brightness: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * decay)
		var tone := sin(TAU * freq * t) * (1.0 - noise)
		tone += 0.5 * brightness * sin(TAU * freq * 2.7 * t)
		var ns := (randf() * 2.0 - 1.0) * noise
		var s := clampf(env * (tone + ns), -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
