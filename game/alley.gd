# Alley controller: keeps the bowling ball parked in its cradle, and auto-returns
# it once a throw finishes — i.e. when the ball reaches the back of the lane or
# settles to near-zero motion (FSD R9). Grabbing/throwing is handled by the
# XR Tools pickable; this script only manages the resting/return state.
extends Node3D

## Speed (m/s) below which the ball is considered "stopped".
const SETTLE_SPEED := 0.25
## Seconds the ball must stay stopped before it returns.
const SETTLE_TIME := 0.8
## Past this z (near the back wall) the ball returns immediately.
const BACK_Z := -6.8

@onready var ball: RigidBody3D = $Ball
@onready var cradle: Marker3D = $BallCradle

var _held := false
var _settle := 0.0

func _ready() -> void:
	ball.picked_up.connect(_on_picked_up)
	ball.dropped.connect(_on_dropped)
	_park_ball()

func _on_picked_up(_p) -> void:
	_held = true

func _on_dropped(_p) -> void:
	_held = false
	_settle = 0.0

func _physics_process(delta: float) -> void:
	# While held, or already parked, there is nothing to do.
	if _held or ball.freeze:
		return

	if ball.linear_velocity.length() < SETTLE_SPEED:
		_settle += delta
	else:
		_settle = 0.0

	if ball.global_position.z < BACK_Z or _settle >= SETTLE_TIME:
		_park_ball()

## Snap the ball back to the cradle and freeze it, ready to be grabbed again.
func _park_ball() -> void:
	_settle = 0.0
	ball.freeze = true
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_transform = cradle.global_transform
