# Practice scene controller: lets the player quit back to the main menu (FSD R12)
# by pressing a face button (B/Y) on either controller.
extends Node3D

const MENU_SCENE := "res://game/menu/main_menu.tscn"

func _ready() -> void:
	for path in ["XROrigin3D/LeftController", "XROrigin3D/RightController"]:
		var c := get_node_or_null(path)
		if c:
			c.button_pressed.connect(_on_button)

func _on_button(button_name: String) -> void:
	if button_name == "by_button" or button_name == "menu_button":
		get_tree().change_scene_to_file(MENU_SCENE)
