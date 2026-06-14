# Dev-only: render a few frames, save a screenshot, then quit.
# Used to visually verify scenes on desktop without the headset.
extends Node3D

@export var shot_path: String = "res://dev/preview.png"
@export var wait_frames: int = 40

## If set, reposition a child "Camera3D" to aim_from and look at aim_at.
@export var use_aim: bool = false
@export var aim_from: Vector3 = Vector3.ZERO
@export var aim_at: Vector3 = Vector3.ZERO

var _count := 0

func _ready() -> void:
	if use_aim:
		var cam := get_node_or_null("Camera3D") as Camera3D
		if cam:
			cam.global_position = aim_from
			cam.look_at(aim_at, Vector3.UP)

func _process(_delta: float) -> void:
	_count += 1
	if _count == wait_frames:
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(shot_path)
		print("SCREENSHOT_SAVED path=", shot_path, " err=", err)
		get_tree().quit()
