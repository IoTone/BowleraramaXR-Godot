# Dev-only: bowl the ball into the rack and report how many pins fall, verifying
# knockdown detection and exercising the collision-audio path (headless = silent
# but must run error-free).
extends Node3D

var ball: RigidBody3D
var rack: Node3D
var frame := 0
var max_down := 0

func _ready() -> void:
	var alley := preload("res://game/alley.tscn").instantiate()
	add_child(alley)
	ball = alley.get_node("Ball")
	rack = alley.get_node("PinRack")
	await get_tree().physics_frame
	print("pins_racked=", rack.get_child_count())
	ball.freeze = false
	ball.global_position = Vector3(0.0, 0.3, -1.0)
	ball.linear_velocity = Vector3(0.0, 0.0, -7.0)
	print("THROWN at pins")

func _physics_process(_delta: float) -> void:
	frame += 1
	max_down = max(max_down, rack.down_count())
	# Once the ball has parked, the alley should have swept the fallen pins.
	if frame > 30 and ball.freeze:
		print("PINS_TEST_DONE max_down=%d/10 remaining_pins=%d (max_down+remaining should=10)" % [max_down, rack.get_child_count()])
		get_tree().quit()
	if frame >= 300:
		print("TIMEOUT max_down=%d remaining=%d frozen=%s" % [max_down, rack.get_child_count(), str(ball.freeze)])
		get_tree().quit()
