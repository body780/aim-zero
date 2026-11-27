class_name SpawnLayout
extends RefCounted

# Choose within the room's visible training wall, measured from the eye.
static func point(rng: RandomNumberGenerator, eye: Vector3, yaw: float, targets: Array, slot: int, human: bool) -> Vector3:
	var best := Vector3.ZERO
	var largest_gap := -1.0
	for attempt in 96:
		var depth := rng.randf_range(7.8, 11.0)
		var heading := deg_to_rad(rng.randf_range(-30, 30))
		var height := 0.0 if human else rng.randf_range(-5, 10)
		var direction := RangeGeometry.aim_direction(Vector2(heading, deg_to_rad(height)))
		var candidate := eye + direction * depth
		var gap := absf(wrapf(heading - yaw, -PI, PI))
		for i in targets.size():
			var other: RangeSession.Target = targets[i]
			if other.active and (i != slot or other.position != Vector3.ZERO):
				gap = minf(gap, direction.angle_to((other.point(false) - eye).normalized()))
		if gap > largest_gap:
			best = candidate
			largest_gap = gap
		if gap >= deg_to_rad(7):
			break
	return best - RangeGeometry.HEAD if human else best

static func micro(rng: RandomNumberGenerator, eye: Vector3, anchor: Vector2) -> Vector3:
	# Pull the sampling cone inside the playable wall without clamping each sample.
	var center := anchor.clamp(Vector2(-0.38,-0.06), Vector2(0.38,0.15))
	var radius := deg_to_rad(sqrt(rng.randf_range(1.5 * 1.5, 5.5 * 5.5)))
	var offset := Vector2.from_angle(rng.randf_range(-PI, PI)) * radius
	return eye + RangeGeometry.aim_direction(center + offset) * rng.randf_range(8, 9)
