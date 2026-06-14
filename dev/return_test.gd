# Dev-only: verify alley.gd auto-returns the ball to its cradle after a throw,
# without needing XR. Throws the ball, waits for it to be re-parked, reports.
extends Node3D

var ball: RigidBody3D
var cradle_pos: Vector3
var frame := 0
var thrown := false

func _ready() -> void:
	var alley := preload("res://game/alley.tscn").instantiate()
	add_child(alley)
	ball = alley.get_node("Ball")
	cradle_pos = (alley.get_node("BallCradle") as Marker3D).global_position
	await get_tree().physics_frame
	# Simulate a throw down the lane.
	ball.freeze = false
	ball.global_position = Vector3(0.0, 0.45, -1.0)
	ball.linear_velocity = Vector3(0.0, 0.0, -4.0)
	thrown = true
	print("THROWN from z=-1.0")

func _physics_process(_delta: float) -> void:
	if not thrown:
		return
	frame += 1
	# After the throw, the ball is unfrozen; alley.gd re-freezes it on return.
	if frame > 5 and ball.freeze:
		var d := ball.global_position.distance_to(cradle_pos)
		print("RETURNED frame=%d dist_to_cradle=%.4f" % [frame, d])
		get_tree().quit()
	if frame > 600:
		print("TIMEOUT z=%.3f frozen=%s" % [ball.global_position.z, str(ball.freeze)])
		get_tree().quit()
