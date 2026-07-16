# Parks this node comfortably in front of the player's headset.
#
# Placing XR content at fixed world coordinates is a trap. Under OpenXR's
# default "Stage" reference space the tracking origin is the centre of the
# guardian, so the pose the player launches with — position *and* yaw — is
# simply wherever they happen to be standing and whichever way they happen to be
# facing. Content nailed to world space can therefore end up beside or behind
# them. This node re-derives its transform from the live camera pose instead.
#
# It snaps into place on the first tracked frame, then re-follows only once the
# player has drifted outside a comfort window, so a pointer-driven UI does not
# jitter under the reticle while they are trying to click it.
class_name XRAnchorInView
extends Node3D

## Camera to track. Falls back to the first XRCamera3D in the scene.
@export var camera_path: NodePath

## Metres in front of the camera to park the anchor.
@export_range(0.5, 5.0, 0.1) var distance: float = 1.6

## Offset from eye level, in metres. Slightly low reads as more comfortable
## than dead-centre, which tends to feel like it is looming.
@export_range(-1.0, 1.0, 0.05) var height_offset: float = -0.15

## Re-follow once the player's gaze is more than this many degrees off-anchor.
@export_range(1.0, 90.0, 1.0) var follow_angle_deg: float = 35.0

## Re-follow once the player has walked further than this from the anchor.
@export_range(0.5, 10.0, 0.1) var follow_distance: float = 2.5

## Seconds to ease into a re-follow. 0 snaps instantly.
@export_range(0.0, 2.0, 0.05) var follow_smoothing: float = 0.25

var _camera: XRCamera3D
var _placed := false
var _target := Transform3D.IDENTITY


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as XRCamera3D
	if _camera == null:
		_camera = _find_camera(owner if owner else get_tree().current_scene)
	if _camera == null:
		push_warning("XRAnchorInView: no XRCamera3D found, leaving transform as authored.")
		set_process(false)


## Force the anchor to re-snap in front of the player on the next tracked frame.
## Call this after anything that moves the player in world space (a recenter, a
## teleport) so the panel is re-derived from the new pose instead of sliding in
## from the old one.
func place_now() -> void:
	_placed = false


func _process(delta: float) -> void:
	if not _is_tracking():
		return

	if not _placed:
		# First tracked frame: snap, so the menu is simply *there* the moment the
		# player can see anything at all.
		_target = _desired_transform()
		global_transform = _target
		_placed = true
		return

	if _should_refollow():
		_target = _desired_transform()

	if follow_smoothing > 0.0:
		# Framerate-independent exponential ease.
		global_transform = global_transform.interpolate_with(
			_target, 1.0 - exp(-delta / follow_smoothing))
	else:
		global_transform = _target


# True once the runtime is actually delivering a head pose. Reading the camera
# before this point yields the identity transform, which would park the panel at
# the world origin.
func _is_tracking() -> bool:
	var iface := XRServer.primary_interface
	if iface == null or not iface.is_initialized():
		return false

	var head := XRServer.get_tracker(&"head")
	if head is XRPositionalTracker:
		var pose: XRPose = head.get_pose(&"default")
		if pose != null:
			return pose.has_tracking_data

	# Runtimes that expose no head tracker (e.g. WebXR): once the interface is
	# up, treat the camera pose as live.
	return true


func _should_refollow() -> bool:
	var cam := _camera.global_transform
	var to_anchor := _target.origin - cam.origin

	if to_anchor.length() > follow_distance:
		return true

	# Compare headings on the floor plane; looking up at the sky should not drag
	# the panel around with the player's pitch.
	var bearing := Vector3(to_anchor.x, 0.0, to_anchor.z)
	if bearing.length_squared() < 0.0001:
		return true

	var gaze := floor_heading(cam)
	return gaze.angle_to(bearing.normalized()) > deg_to_rad(follow_angle_deg)


func _desired_transform() -> Transform3D:
	return compute_pose(_camera.global_transform, distance, height_offset)


## The pose that parks a panel `distance` metres in front of `cam`, upright, and
## facing back at it. Pure geometry, so it is directly testable — see
## dev/test_anchor_in_view.gd.
static func compute_pose(
		cam: Transform3D, distance: float, height_offset: float) -> Transform3D:
	var heading := floor_heading(cam)

	var origin := cam.origin + heading * distance
	origin.y = cam.origin.y + height_offset

	# XRTools' Viewport2Din3D quad has its face normal on +Z, so +Z is what has
	# to point back at the player.
	var z_axis := -heading
	var x_axis := Vector3.UP.cross(z_axis).normalized()
	var y_axis := z_axis.cross(x_axis)
	return Transform3D(Basis(x_axis, y_axis, z_axis), origin)


## The camera's forward direction flattened onto the floor plane, normalised.
static func floor_heading(cam: Transform3D) -> Vector3:
	var forward := -cam.basis.z
	var flat := Vector3(forward.x, 0.0, forward.z)

	if flat.length_squared() < 0.000001:
		# Head is pitched (near) straight up or down, so forward carries no
		# heading. The camera's up axis does — it tips backwards when the player
		# looks up and forwards when they look down, hence the sign flip.
		var up := cam.basis.y
		flat = Vector3(up.x, 0.0, up.z) * -signf(forward.y)

	if flat.length_squared() < 0.000001:
		return Vector3.FORWARD

	return flat.normalized()


func _find_camera(node: Node) -> XRCamera3D:
	if node == null:
		return null
	if node is XRCamera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found:
			return found
	return null
