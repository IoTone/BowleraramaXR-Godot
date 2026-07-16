# Practice scene controller.
#   Left-hand PINCH ....... toggle the pop-up menu
#   Right-hand point + trigger ... click the menu buttons (laser pointer)
#   A / X button .......... recenter at the foul line  (controller fallback)
#   B / Y button / menu ... return to the main menu    (controller fallback)
extends Node3D

const MENU_SCENE := "res://game/menu/main_menu.tscn"

@onready var pause_panel: XRToolsViewport2DIn3D = $PausePanel
@onready var _camera: XRCamera3D = $XROrigin3D/XRCamera3D
# The laser pointer used to click the pop-up menu. Only enabled while the menu is
# up, so it doesn't clutter the lane or fight with grabbing the ball. Right hand
# only: the left trigger is the summon/dismiss gesture, so binding the pointer's
# click to it too would dismiss the menu the moment you tried to click.
@onready var _pointer: Node = get_node_or_null("XROrigin3D/RightController/FunctionPointer")

func _ready() -> void:
	var left := get_node_or_null("XROrigin3D/LeftController") as XRController3D
	if left:
		left.button_pressed.connect(_on_left_button)
	var right := get_node_or_null("XROrigin3D/RightController") as XRController3D
	if right:
		right.button_pressed.connect(_on_other_button)
	_show_menu(false)
	# Place the player at the foul line on entry (wait for a valid HMD pose).
	await get_tree().create_timer(0.3).timeout
	_recenter()

func _on_left_button(button_name: String) -> void:
	if button_name == "trigger_click":          # left pinch summons/dismisses
		_show_menu(not pause_panel.visible)
	else:
		_on_other_button(button_name)

func _on_other_button(button_name: String) -> void:
	match button_name:
		"ax_button":
			_recenter()
		"by_button", "menu_button":
			SceneLoader.go(MENU_SCENE)

func _show_menu(show: bool) -> void:
	if show:
		# Park the panel in front of the player, facing them, wherever they're
		# looking when they summon it — so it's readable and within pointer range
		# rather than pinned to some fixed spot they may have turned away from.
		pause_panel.global_transform = XRAnchorInView.compute_pose(
			_camera.global_transform, 1.0, -0.1)
	pause_panel.visible = show
	pause_panel.enabled = show
	if _pointer:
		_pointer.enabled = show

# Snap the XR tracking origin so the player stands at the foul line facing the
# lane, wherever their physical tracking origin happens to be.
func _recenter() -> void:
	var xr := XRServer.primary_interface
	if xr and xr.is_initialized():
		XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
