# Dev-only: size the window to the menu's real resolution, render a few frames,
# screenshot, and quit. Used to verify 2D UI layout without a headset.
extends Node

@export var shot_path: String = "res://dev/ui_preview.png"
@export var win_size: Vector2i = Vector2i(560, 400)
@export var wait_frames: int = 20

var _count := 0

func _ready() -> void:
	get_window().size = win_size

func _process(_delta: float) -> void:
	_count += 1
	if _count == wait_frames:
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(shot_path)
		print("SCREENSHOT_SAVED path=", shot_path, " err=", err)
		get_tree().quit()
