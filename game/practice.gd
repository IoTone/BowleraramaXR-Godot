# Practice scene controller.
#   Left-hand PINCH ....... toggle the pop-up menu (poke its buttons to use them)
#   A / X button .......... recenter at the foul line  (controller fallback)
#   B / Y button / menu ... return to the main menu    (controller fallback)
extends Node3D

const MENU_SCENE := "res://game/menu/main_menu.tscn"

@onready var pause_panel: XRToolsViewport2DIn3D = $PausePanel

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
			get_tree().change_scene_to_file(MENU_SCENE)

func _show_menu(show: bool) -> void:
	pause_panel.visible = show
	pause_panel.enabled = show

# Snap the XR tracking origin so the player stands at the foul line facing the
# lane, wherever their physical tracking origin happens to be.
func _recenter() -> void:
	var xr := XRServer.primary_interface
	if xr and xr.is_initialized():
		XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
