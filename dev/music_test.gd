# Dev-only: pull samples straight from the MusicDirector synth and check the
# output is audible (non-silent) and bounded (no clipping). Headless = the audio
# device is silent, so we measure the generated buffer directly.
extends Node

func _ready() -> void:
	var md := get_node("/root/Music")
	var count := 88200  # ~4 seconds at 22050 Hz
	var peak := 0.0
	var sumsq := 0.0
	var nonzero := 0
	for i in count:
		var f: Vector2 = md._next_sample()
		var a := absf(f.x)
		peak = maxf(peak, a)
		sumsq += f.x * f.x
		if a > 0.0001:
			nonzero += 1
	var rms := sqrt(sumsq / count)
	print("MUSIC_TEST rms=%.4f peak=%.4f nonzero=%d/%d clip=%s" % [rms, peak, nonzero, count, str(peak > 1.001)])
	get_tree().quit()
