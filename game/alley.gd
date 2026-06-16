# Alley controller: keeps the bowling ball parked in its cradle, and auto-returns
# it once a throw finishes — i.e. when the ball reaches the back of the lane or
# settles to near-zero motion (FSD R9). Grabbing/throwing is handled by the
# XR Tools pickable; this script only manages the resting/return state.
extends Node3D

## Speed (m/s) below which the ball is considered "stopped".
const SETTLE_SPEED := 0.25
## Seconds the ball must stay stopped before it returns.
const SETTLE_TIME := 0.8
## Play-surface bounds — leaving any of these resets the ball immediately.
const BACK_Z := -7.0        ## past the pins / back wall
const FRONT_Z := 0.8        ## rolled back behind the approach
const SIDE_X := 0.7         ## off the side of the lane/approach
const FLOOR_Y := -0.5       ## fell below the floor
## Minimum ball speed (m/s) for an impact sound.
const BALL_SFX_MIN_SPEED := 0.8

@onready var ball: RigidBody3D = $Ball
@onready var cradle: Marker3D = $BallCradle
@onready var rack: Node3D = $PinRack

var _held := false
var _settle := 0.0
var _last_ball_sfx_ms := 0

func _ready() -> void:
	ball.picked_up.connect(_on_picked_up)
	ball.dropped.connect(_on_dropped)
	ball.body_entered.connect(_on_ball_body_entered)
	_park_ball()

func _on_ball_body_entered(body: Node) -> void:
	if _held or ball.freeze:
		return
	var speed := ball.linear_velocity.length()
	if speed < BALL_SFX_MIN_SPEED:
		return
	var now := Time.get_ticks_msec()
	if now - _last_ball_sfx_ms < 60:
		return
	_last_ball_sfx_ms = now
	if body is BowlPin:
		Sfx.play("ball_hit", ball.global_position, speed / 4.0)
	else:
		Sfx.play("ball_touch", ball.global_position, speed / 5.0)

func _on_picked_up(_p) -> void:
	_held = true
	Sfx.play("grab", ball.global_position, 1.0)
	_set_ball_glow(3.2)

func _on_dropped(_p) -> void:
	_held = false
	_settle = 0.0
	_set_ball_glow(1.3)

## Brighten the ball's emission while it's held so it reads as "active".
func _set_ball_glow(energy: float) -> void:
	var mi := ball.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mi:
		var mat := mi.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = energy

func _physics_process(delta: float) -> void:
	# While held, or already parked, there is nothing to do.
	if _held or ball.freeze:
		return

	# Off the play surface (rolled behind, off the side, past the pins, or fell)?
	var p := ball.global_position
	if p.z > FRONT_Z or p.z < BACK_Z or absf(p.x) > SIDE_X or p.y < FLOOR_Y:
		_park_ball()
		return

	if ball.linear_velocity.length() < SETTLE_SPEED:
		_settle += delta
	else:
		_settle = 0.0

	if _settle >= SETTLE_TIME:
		_park_ball()

## Snap the ball back to the cradle and freeze it, ready to be grabbed again.
## Sweeping fallen pins happens here so the lane clears on every ball return.
func _park_ball() -> void:
	_settle = 0.0
	ball.freeze = true
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_transform = cradle.global_transform
	rack.clear_fallen()
