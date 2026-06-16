# Dev-only: roll the ball backward off the approach and confirm it resets to the
# cradle quickly (play-surface bounds), rather than rolling away forever.
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
	ball.freeze = false
	ball.linear_velocity = Vector3(0.0, 0.0, 3.0)  # roll backward, behind the player
	thrown = true
	print("DROPPED rolling backward (+z)")

func _physics_process(_delta: float) -> void:
	if not thrown:
		return
	frame += 1
	if frame > 5 and ball.freeze:
		print("RESET_OK frame=%d dist_to_cradle=%.3f" % [frame, ball.global_position.distance_to(cradle_pos)])
		get_tree().quit()
	if frame > 200:
		print("RESET_FAIL z=%.2f frozen=%s" % [ball.global_position.z, str(ball.freeze)])
		get_tree().quit()
