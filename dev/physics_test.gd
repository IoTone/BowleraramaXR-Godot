# Dev-only: drop a dynamic ball over the lane with forward velocity and log its
# trajectory, to verify gravity + lane collision + rolling without a headset.
extends Node3D

var ball: RigidBody3D
var frame := 0

func _ready() -> void:
	var alley := preload("res://game/alley.tscn").instantiate()
	add_child(alley)
	ball = preload("res://game/ball/ball.tscn").instantiate()
	add_child(ball)
	ball.freeze = false
	ball.global_position = Vector3(0.0, 0.45, -1.0)
	ball.linear_velocity = Vector3(0.0, 0.0, -4.0)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame % 15 == 0:
		var p := ball.global_position
		print("F%03d y=%.3f z=%.3f vz=%.2f" % [frame, p.y, p.z, ball.linear_velocity.z])
	if frame >= 180:
		var p := ball.global_position
		print("PHYS_TEST_DONE rest_y=%.3f end_z=%.3f" % [p.y, p.z])
		get_tree().quit()
