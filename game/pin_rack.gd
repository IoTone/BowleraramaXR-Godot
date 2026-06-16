# Racks the 10 pins in standard layout. When the ball resets, fallen pins are
# swept away (counted as knocked out, FSD R8); once the rack is empty it refills
# so practice continues (R10).
extends Node3D

const PIN_SCENE := preload("res://game/pin/pin.tscn")
const LANE_TOP := 0.1
const HEAD_Z := -6.0
const SPACING := 0.3048           # 12 inches, centre-to-centre
const ROW_DZ := 0.2640            # SPACING * sin(60)
const RERACK_DELAY := 2.0

## Each entry: [pin_number, x in spacings, row index from the head pin].
const LAYOUT := [
	[1, 0.0, 0],
	[2, -0.5, 1], [3, 0.5, 1],
	[4, -1.0, 2], [5, 0.0, 2], [6, 1.0, 2],
	[7, -1.5, 3], [8, -0.5, 3], [9, 0.5, 3], [10, 1.5, 3],
]

signal all_cleared

var _pins: Array[BowlPin] = []
var _reracking := false

func _ready() -> void:
	_rack()

func _rack() -> void:
	for p in _pins:
		if is_instance_valid(p):
			p.queue_free()
	_pins.clear()
	_reracking = false
	for entry in LAYOUT:
		var pin: BowlPin = PIN_SCENE.instantiate()
		pin.pin_number = entry[0]
		add_child(pin)
		pin.global_position = Vector3(entry[1] * SPACING, LANE_TOP, HEAD_Z - entry[2] * ROW_DZ)
		_pins.append(pin)

## Sweep away any pins that have fallen. Called when the ball resets. When the
## rack is emptied, re-rack a fresh set after a short delay.
func clear_fallen() -> void:
	if _reracking:
		return
	var standing: Array[BowlPin] = []
	for p in _pins:
		if not is_instance_valid(p):
			continue
		if p.is_down:
			p.queue_free()
		else:
			standing.append(p)
	_pins = standing
	if _pins.is_empty():
		_reracking = true
		all_cleared.emit()
		_rerack()

func _rerack() -> void:
	await get_tree().create_timer(RERACK_DELAY).timeout
	_rack()

## Pins currently knocked down (still present). Used by dev tests.
func down_count() -> int:
	var c := 0
	for p in _pins:
		if is_instance_valid(p) and p.is_down:
			c += 1
	return c
