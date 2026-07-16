# Main menu root.
#
# Aligns the tracking origin to wherever the player is actually standing and
# facing when the session starts. Without this, the guardian's origin decides
# which way "forward" is, so the player can boot the game looking at the
# synthwave horizon with the menu somewhere off to their side — and would then
# load into the alley facing the wrong way too, since the recenter carries over
# to the practice scene via XRServer.
extends Node3D

@onready var _start_xr: XRToolsStartXR = $StartXR
@onready var _menu_anchor: XRAnchorInView = $MenuAnchor


func _ready() -> void:
	_start_xr.xr_started.connect(_on_xr_started)


func _on_xr_started() -> void:
	# xr_started fires on focus, which can land a frame before the runtime hands
	# over the first tracked pose. Recentering on a stale pose would defeat the
	# point, so sample on the next frame.
	await get_tree().process_frame

	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

	# The recenter just moved the player in world space, so re-derive the panel
	# pose from where they now are rather than easing over from the old one.
	_menu_anchor.place_now()
