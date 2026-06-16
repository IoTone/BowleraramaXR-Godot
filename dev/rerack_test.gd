# Dev-only: force all pins down and confirm the rack emits all_cleared and
# re-racks a fresh set of 10 (FSD R10).
extends Node3D

var rack: Node3D
var cleared := false
var t := 0.0

func _ready() -> void:
	var alley := preload("res://game/alley.tscn").instantiate()
	add_child(alley)
	rack = alley.get_node("PinRack")
	rack.all_cleared.connect(func() -> void:
		cleared = true
		print("ALL_CLEARED emitted"))
	await get_tree().physics_frame
	for p in rack.get_children():
		(p as BowlPin).is_down = true
	print("forced all 10 down; waiting for re-rack (2.5s)...")

func _process(delta: float) -> void:
	t += delta
	if t > 3.2:
		var standing := 0
		for p in rack.get_children():
			if not (p as BowlPin).is_down:
				standing += 1
		print("RERACK_DONE cleared=%s pins_now=%d standing=%d" % [str(cleared), rack.get_child_count(), standing])
		get_tree().quit()
