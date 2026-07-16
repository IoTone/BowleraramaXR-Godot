# Rasterises the icon SVGs to the PNGs the Android exporter needs.
#
# Godot (via ThorVG) is the rasteriser rather than ImageMagick, whose built-in
# SVG renderer silently drops gradients -- you get a black ball on a black sky.
# Using the engine also proves the SVG renders correctly in the thing that
# actually ships it.
#
#   godot --headless --path . --script res://icons/render_icons.gd
extends SceneTree

const SRC_SIZE := 432.0  # the SVGs' intrinsic size

# src, output, pixel size
const JOBS := [
	["res://icon.svg", "res://icons/icon_192.png", 192],
	["res://icons/icon_foreground.svg", "res://icons/icon_fg_432.png", 432],
	["res://icons/icon_background.svg", "res://icons/icon_bg_432.png", 432],
]


func _init() -> void:
	var failed := 0
	for job in JOBS:
		if not _render(job[0], job[1], job[2]):
			failed += 1
	print("RENDER_ICONS %s" % ("PASS" if failed == 0 else "FAIL (%d)" % failed))
	quit(1 if failed > 0 else 0)


func _render(src: String, dst: String, size: int) -> bool:
	if not FileAccess.file_exists(src):
		push_error("missing %s -- run icons/gen_icon.py first" % src)
		return false

	var markup := FileAccess.get_file_as_string(src)
	var img := Image.new()
	var err := img.load_svg_from_string(markup, size / SRC_SIZE)
	if err != OK or img.is_empty():
		push_error("failed to rasterise %s (err %d)" % [src, err])
		return false

	err = img.save_png(dst)
	if err != OK:
		push_error("failed to write %s (err %d)" % [dst, err])
		return false

	print("  %s -> %s (%dx%d)" % [src, dst, img.get_width(), img.get_height()])
	return true
