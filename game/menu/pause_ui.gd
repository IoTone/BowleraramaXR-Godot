# In-alley pause panel, rendered to a 3D quad and driven by the hand pointer
# (aim + pinch). Hands-only friendly — no physical buttons needed.
#   RECENTER -> snap the player back to the foul line
#   MENU ..... return to the main menu (FSD R12)
extends Control

const MENU_SCENE := "res://game/menu/main_menu.tscn"

const CYAN := Color(0.0, 1.0, 1.0)
const MAGENTA := Color(1.0, 0.1, 0.7)
const WHITE := Color(0.92, 0.92, 1.0)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.0, 0.10, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24
	v.offset_right = -24
	v.offset_top = 18
	v.offset_bottom = -18
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	add_child(v)

	var title := Label.new()
	title.text = "BowleramaXR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", MAGENTA)
	v.add_child(title)

	v.add_child(_button("RECENTER", _on_recenter))
	v.add_child(_button("MENU", _on_menu))

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Fire on press, not release — a poke rarely releases cleanly on the button.
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", CYAN)
	b.add_theme_color_override("font_hover_color", WHITE)
	b.add_theme_color_override("font_pressed_color", WHITE)
	b.add_theme_stylebox_override("normal", _box(Color(0.10, 0.0, 0.20, 0.85), CYAN))
	b.add_theme_stylebox_override("hover", _box(Color(0.30, 0.0, 0.40, 0.9), MAGENTA))
	b.add_theme_stylebox_override("pressed", _box(Color(0.5, 0.0, 0.5, 0.95), WHITE))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), MAGENTA))
	b.mouse_entered.connect(func() -> void: Sfx.play_2d("ui", -13.0, 1.4))
	b.pressed.connect(func() -> void:
		Sfx.play_2d("ui", -3.0, 1.0)
		cb.call())
	return b

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(3)
	s.border_color = border
	s.set_corner_radius_all(10)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _on_recenter() -> void:
	var xr := XRServer.primary_interface
	if xr and xr.is_initialized():
		XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
