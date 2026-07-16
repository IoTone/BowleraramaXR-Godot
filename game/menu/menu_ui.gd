# Synthwave main-menu UI, built in code (no asset files). Rendered to a 3D quad
# via XRToolsViewport2DIn3D and driven by the controller pointer. Buttons act on
# the SceneTree directly (Practice / About / Quit) — FSD R11.
extends Control

const PRACTICE_SCENE := "res://game/practice.tscn"

const CYAN := Color(0.0, 1.0, 1.0)
const MAGENTA := Color(1.0, 0.1, 0.7)
const WHITE := Color(0.92, 0.92, 1.0)

var _about: Panel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.0, 0.10, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var col := _centered_column()
	add_child(col)

	var title := _label("BowleramaXR", 64, CYAN)
	col.add_child(title)
	col.add_child(_label("SYNTHWAVE BOWLERAMA", 20, MAGENTA))
	col.add_child(_spacer(20))
	col.add_child(_button("PRACTICE", _on_practice))
	col.add_child(_button("ABOUT", _on_about))
	col.add_child(_button("QUIT", _on_quit))

	_about = _build_about()
	add_child(_about)
	_about.visible = false

func _centered_column() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 40
	v.offset_right = -40
	v.offset_top = 30
	v.offset_bottom = -30
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	return v

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Fire on press, not release — robust for poke/pointer in XR.
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.add_theme_font_size_override("font_size", 32)
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
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _build_about() -> Panel:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", _box(Color(0.04, 0.0, 0.10, 0.98), MAGENTA))
	var v := _centered_column()
	p.add_child(v)
	v.add_child(_label("ABOUT", 48, CYAN))
	var body := _label(
		"A synthwave bowling prototype for Android XR.\n\n" +
		"Grip to grab the ball, swing, and release to bowl.\n" +
		"Knock down all ten neon pins!\n\n" +
		"Visuals, sound, and music are all generated in-engine.",
		22, WHITE)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	v.add_child(_spacer(10))
	v.add_child(_button("BACK", func() -> void: _about.visible = false))
	return p

func _on_practice() -> void:
	# Load in the background so the menu keeps rendering and the music keeps
	# playing instead of freezing mid-transition (see SceneLoader).
	_show_loading()
	SceneLoader.go(PRACTICE_SCENE)

func _show_loading() -> void:
	var o := ColorRect.new()
	o.color = Color(0.04, 0.0, 0.10, 0.96)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Swallow further clicks while the next scene loads.
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(o)
	var l := _label("LOADING…", 44, CYAN)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	o.add_child(l)

func _on_about() -> void:
	_about.visible = true

func _on_quit() -> void:
	get_tree().quit()
