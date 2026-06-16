# A bowling pin: procedurally-built mesh (surface of revolution, shared across
# all 10 pins), knockdown detection that latches (FSD R8), a floating number
# (R3), and wood-clack collision audio (R6).
class_name BowlPin
extends RigidBody3D

## Standard pin number (1-10), shown on the floating label.
@export var pin_number: int = 1

## Tilt past this (dot of up-vector with world up) counts as a real fall.
## ~0.6 ≈ 53° of lean — a clear topple, not a wobble from a tap.
const DOWN_DOT := 0.6
## Horizontal distance (m) off its spot that also counts as knocked out — large
## enough that a light tap which leaves the pin standing does NOT count.
const DOWN_DISP := 0.25
## Minimum impact speed (m/s) to trigger a clack (low, so light taps still tick).
const SFX_MIN_SPEED := 0.3

static var _shared_mesh: ArrayMesh

var is_down := false
var _last_sfx_ms := 0
var _start_pos := Vector3.ZERO
var _started := false

@onready var _mesh_instance: MeshInstance3D = $Mesh
@onready var _label: Label3D = $Number

func _ready() -> void:
	if _shared_mesh == null:
		_shared_mesh = _build_pin_mesh()
	_mesh_instance.mesh = _shared_mesh
	_label.text = str(pin_number)
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# Capture the resting spot on the first frame (after the rack positions us).
	if not _started:
		_start_pos = global_position
		_started = true
		return
	if is_down:
		return
	var tilted := global_transform.basis.y.normalized().dot(Vector3.UP) < DOWN_DOT
	var disp := Vector2(global_position.x - _start_pos.x, global_position.z - _start_pos.z).length()
	if tilted or disp > DOWN_DISP:
		is_down = true

func _on_body_entered(body: Node) -> void:
	# Pins voice pin-vs-pin and pin-vs-lane/wall (static). The ball plays its own
	# "ball_hit", so ignore ball contacts (a moving RigidBody that isn't a pin).
	if not (body is BowlPin or body is StaticBody3D):
		return
	var speed := linear_velocity.length()
	if speed < SFX_MIN_SPEED:
		return
	var now := Time.get_ticks_msec()
	if now - _last_sfx_ms < 60:
		return
	_last_sfx_ms = now
	Sfx.play("pin_hit", global_position, speed / 4.0)

## Build a pin profile (radius, height) and lathe it into a mesh.
static func _build_pin_mesh() -> ArrayMesh:
	var profile := [
		Vector2(0.025, 0.00), Vector2(0.035, 0.02), Vector2(0.052, 0.05),
		Vector2(0.060, 0.08), Vector2(0.057, 0.12), Vector2(0.040, 0.18),
		Vector2(0.026, 0.24), Vector2(0.022, 0.27), Vector2(0.030, 0.30),
		Vector2(0.038, 0.33), Vector2(0.030, 0.36), Vector2(0.010, 0.38),
	]
	var segs := 16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(profile.size() - 1):
		var r0: float = profile[i].x
		var y0: float = profile[i].y
		var r1: float = profile[i + 1].x
		var y1: float = profile[i + 1].y
		for s in range(segs):
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p11)
			st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p01)
	# Bottom cap.
	var rb: float = profile[0].x
	var yb: float = profile[0].y
	for s in range(segs):
		var a0 := TAU * s / segs
		var a1 := TAU * (s + 1) / segs
		st.add_vertex(Vector3(0, yb, 0))
		st.add_vertex(Vector3(cos(a1) * rb, yb, sin(a1) * rb))
		st.add_vertex(Vector3(cos(a0) * rb, yb, sin(a0) * rb))
	st.generate_normals()
	return st.commit()
