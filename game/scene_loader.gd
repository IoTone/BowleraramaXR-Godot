# SceneLoader (autoload): swaps scenes without the hitch that
# change_scene_to_file() causes.
#
# change_scene_to_file() loads AND instantiates the target on the main thread,
# which for the alley (pins, ball, shaders) stalls rendering for hundreds of
# milliseconds. In XR that reads as a hard freeze, and it starves the in-engine
# music synth (a short generator buffer underruns → the track cuts out). Here the
# heavy load runs on a background thread while the *current* scene keeps
# rendering and feeding audio; only the final swap touches the main thread, and a
# ready PackedScene instantiates fast.
extends Node

## Emitted each frame while loading, 0.0 → 1.0. UIs can show progress.
signal progress(value: float)

var _path := ""
var _busy := false


func _ready() -> void:
	set_process(false)


## Begin loading `path` in the background and switch to it when ready. Ignored if
## a load is already in flight.
func go(path: String) -> void:
	if _busy:
		return
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("SceneLoader: could not start loading %s (err %d)" % [path, err])
		return
	_path = path
	_busy = true
	set_process(true)


func _process(_delta: float) -> void:
	var parts := []
	var status := ResourceLoader.load_threaded_get_status(_path, parts)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress.emit(float(parts[0]) if parts.size() > 0 else 0.0)
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed: PackedScene = ResourceLoader.load_threaded_get(_path)
			_finish()
			# Swap only once the scene is fully loaded; this is the one cheap
			# main-thread step.
			get_tree().change_scene_to_packed(packed)
		_:
			push_error("SceneLoader: failed to load %s (status %d)" % [_path, status])
			_finish()


func _finish() -> void:
	_busy = false
	_path = ""
	set_process(false)
