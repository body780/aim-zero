class_name RangeGeometry
extends RefCounted

const BODY := [
	[Vector3(0.0, 1.18, 0), Vector3(0.42, 0.47, 0.27)],
	[Vector3(0.0, 0.853, 0), Vector3(0.32, 0.19, 0.23)],
	[Vector3(-0.275, 1.12, 0), Vector3(0.12, 0.45, 0.17)],
	[Vector3(0.275, 1.12, 0), Vector3(0.12, 0.45, 0.17)],
	[Vector3(-0.117, 0.456, 0), Vector3(0.16, 0.73, 0.2)],
	[Vector3(0.117, 0.456, 0), Vector3(0.16, 0.73, 0.2)],
	[Vector3(-0.117, 0.07, -0.035), Vector3(0.18, 0.14, 0.29)],
	[Vector3(0.117, 0.07, -0.035), Vector3(0.18, 0.14, 0.29)],
]
const HEAD := Vector3(0, Drills.EYE_HEIGHT, 0)
const HEAD_RADIUS := 0.126
const PLAYER_RADIUS := 0.26
const FLOOR_SIZE := Vector2(13.35, 16.5)
const COVER := [
	AABB(Vector3(-2.1, 0, -6.35), Vector3(4.2, 2.45, 0.78)),
	AABB(Vector3(-5.70, 0, -9.65), Vector3(1.47, 2.1, 1.12)),
	AABB(Vector3(4.25, 0, -10.55), Vector3(1.5, 2.25, 1.5)),
	AABB(Vector3(-0.80, 0, -12.7), Vector3(1.6, 2.38, 0.8)),
]


static func aim_direction(look: Vector2) -> Vector3:
	var flat := cos(look.y)
	return Vector3(-sin(look.x) * flat, sin(look.y), -cos(look.x) * flat)


static func angles(from: Vector3, point: Vector3) -> Vector2:
	var diff := point - from
	return Vector2(atan2(-diff.x, -diff.z), atan2(diff.y, Vector2(diff.x, diff.z).length()))


static func angular_error(wanted: Vector2, actual: Vector2) -> Vector2:
	return Vector2(wrapf(actual.x - wanted.x, -PI, PI), actual.y - wanted.y)


static func sphere_distance(origin: Vector3, ray: Vector3, center: Vector3, radius: float) -> float:
	var offset := origin - center
	var projection := offset.dot(ray)
	var discriminant := radius * radius - offset.cross(ray).length_squared()
	if discriminant < 0.0:
		return INF
	var radius_offset := sqrt(discriminant)
	return maxf(0.0, -projection - radius_offset) if -projection + radius_offset >= 0.0 else INF


static func box_distance(origin: Vector3, ray: Vector3, box: AABB) -> float:
	var near := 0.0
	var far := INF
	for axis in 3:
		if absf(ray[axis]) < 0.0000001:
			if origin[axis] < box.position[axis] or origin[axis] > box.end[axis]:
				return INF
			continue
		var low := (box.position[axis] - origin[axis]) / ray[axis]
		var high := (box.end[axis] - origin[axis]) / ray[axis]
		near = maxf(near, minf(low, high))
		far = minf(far, maxf(low, high))
		if near > far:
			return INF
	return near


static func obstruction(origin: Vector3, ray: Vector3, cover: bool) -> float:
	if not cover:
		return INF
	var nearest := INF
	for box: AABB in COVER:
		nearest = minf(nearest, box_distance(origin, ray, box))
	return nearest


static func move_player(position: Vector3, motion: Vector3, cover: bool) -> Vector3:
	var result := position
	for axis in [0, 2]:
		var end := result[axis] + motion[axis]
		if cover:
			var other: int = 2 if axis == 0 else 0
			for box: AABB in COVER:
				if result[other] <= box.position[other] - PLAYER_RADIUS or result[other] >= box.end[other] + PLAYER_RADIUS:
					continue
				var low := box.position[axis] - PLAYER_RADIUS
				var high := box.end[axis] + PLAYER_RADIUS
				if result[axis] <= low and end > low:
					end = low
				elif result[axis] >= high and end < high:
					end = high
		result[axis] = end
	result.x = clampf(result.x, -FLOOR_SIZE.x * 0.5 + PLAYER_RADIUS, FLOOR_SIZE.x * 0.5 - PLAYER_RADIUS)
	result.z = clampf(result.z, -FLOOR_SIZE.y + PLAYER_RADIUS, 2.9)
	return result
