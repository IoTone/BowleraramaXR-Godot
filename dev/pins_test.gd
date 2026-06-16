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
	if frame % 30 == 0:
		var p := ball.global_position
		var pin1 := rack.get_child(0) as Node3D
		var pp := pin1.global_position
		var updot := pin1.global_transform.basis.y.normalized().dot(Vector3.UP)
		print("F%03d ball z=%.2f vz=%.2f | pin1 z=%.3f y=%.3f up=%.2f frozen=%s sleep=%s down=%d" % [frame, p.z, ball.linear_velocity.z, pp.z, pp.y, updot, str(pin1.freeze), str(pin1.sleeping), rack.down_count()])
	if frame >= 200:
		print("PINS_TEST_DONE max_down=%d/10 final=%d" % [max_down, rack.down_count()])
		get_tree().quit()
