# Racks the 10 pins in standard layout, watches for an all-down clear (FSD R10),
# then re-racks so practice continues.
extends Node3D

const PIN_SCENE := preload("res://game/pin/pin.tscn")
const LANE_TOP := 0.1
const HEAD_Z := -6.0
const SPACING := 0.3048           # 12 inches, centre-to-centre
const ROW_DZ := 0.2640            # SPACING * sin(60)
const RERACK_DELAY := 2.5

## Each entry: [pin_number, x in spacings, row index from the head pin].
const LAYOUT := [
	[1, 0.0, 0],
	[2, -0.5, 1], [3, 0.5, 1],
	[4, -1.0, 2], [5, 0.0, 2], [6, 1.0, 2],
	[7, -1.5, 3], [8, -0.5, 3], [9, 0.5, 3], [10, 1.5, 3],
]

signal all_cleared

var _pins: Array[BowlPin] = []
var _cleared := false

func _ready() -> void:
	_rack()

func _rack() -> void:
	for p in _pins:
		if is_instance_valid(p):
			p.queue_free()
	_pins.clear()
	_cleared = false
	for entry in LAYOUT:
		var pin: BowlPin = PIN_SCENE.instantiate()
		pin.pin_number = entry[0]
		add_child(pin)
		pin.global_position = Vector3(entry[1] * SPACING, LANE_TOP, HEAD_Z - entry[2] * ROW_DZ)
		_pins.append(pin)

func _process(_delta: float) -> void:
	if _cleared:
		return
	for p in _pins:
		if not p.is_down:
			return
	_cleared = true
	all_cleared.emit()
	_rerack()

func _rerack() -> void:
	await get_tree().create_timer(RERACK_DELAY).timeout
	_rack()

## Number of pins currently knocked down.
func down_count() -> int:
	var c := 0
	for p in _pins:
		if p.is_down:
			c += 1
	return c
