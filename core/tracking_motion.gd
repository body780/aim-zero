class_name TrackingMotion
extends RefCounted

var angles := Vector2.ZERO
var velocity := Vector2.ZERO
var desired := Vector2.ZERO
var remaining := 0.0

func advance(rng: RandomNumberGenerator, reactive: bool, level: int, dt: float) -> Vector3:
	var gain := 1.0 + 0.08 * (level - 3)
	var acceleration := (150.0 if reactive else 40.0) * gain
	remaining -= dt
	if remaining <= 0.0:
		var speed := rng.randf_range(18, 35) if reactive else rng.randf_range(9, 19)
		var direction := Vector2.from_angle(rng.randf_range(-PI, PI))
		desired = Vector2(direction.x, direction.y * 0.4).normalized() * speed * gain
		remaining = rng.randf_range(0.20, 0.60) if reactive else rng.randf_range(0.65, 1.45)
	# Begin steering before reaching the room edge, using stopping distance.
	for axis in 2:
		var limit := 25.0 if axis == 0 else 8.0
		var stopping := velocity[axis] * velocity[axis] / (2.0 * acceleration)
		if absf(angles[axis]) + stopping >= limit:
			desired[axis] = -signf(angles[axis]) * maxf(4.0, absf(desired[axis]))
	velocity = velocity.move_toward(desired, dt * acceleration)
	angles += velocity * dt
	return RangeGeometry.aim_direction(angles * (PI / 180.0))
