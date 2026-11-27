class_name RangeSession
extends RefCounted

class Target:
	var base := Vector3.ZERO
	var position := Vector3.ZERO
	var previous := Vector3.ZERO
	var presented := Vector3.ZERO
	var radius := 0.3
	var human := false
	var active := false
	var visible := false
	var displayed := false
	var expired_on_screen := false
	var born := 0.0
	var seen_at := -1.0
	var seen_look := Vector2.ZERO
	var seen_eye := Vector3.ZERO

	func point(rendered: bool) -> Vector3:
		var center := presented if rendered else position
		return center + RangeGeometry.HEAD if human else center


var rng := RandomNumberGenerator.new()
var spread_rng := RandomNumberGenerator.new()
var plan: Array = []
var mode := ""
var stage_mode := ""
var stage_index := -1
var elapsed := 0.0
var duration := 0.0
var stage_elapsed := 0.0
var stage_duration := 0.0
var finished := false
var level := 3
var targets: Array[Target] = []
var stages: Array = []
var metrics := TrainingMetrics.new()
var total := TrainingMetrics.new()
var player := Vector3.ZERO
var previous_player := Vector3.ZERO
var visible_eye := Vector3(0, Drills.EYE_HEIGHT, 0)
var velocity := Vector3.ZERO
var accurate := true
var lane_start := 0.0
var pending_at := 0.0
var shot_ready := 0.0
var continuous_target := false
var cover := false
var peek_index := 0
var motion := TrackingMotion.new()
var trigger_held := false
var last_track_time := 0.0
var track_aligned := false
var shown_look := Vector2.ZERO
var shown_speed := 0.0
var previous_velocity := Vector3.ZERO
var shown_time := 0.0
var shown_stop_kind := "release"
var last_stop_kind := "release"
var shot_feedback := ""
var session_seed := 0
var last_view := Vector2.ZERO
var grid_reference := Vector2.ZERO

func _init() -> void:
	for index in 6:
		targets.append(Target.new())


func begin(selected_mode: String, seconds: int, difficulty: int, order: Array, seed_value: int = 0) -> void:
	rng.randomize()
	if seed_value != 0:
		rng.seed = seed_value
	session_seed = rng.seed
	spread_rng.seed = session_seed ^ 314159
	mode = selected_mode
	plan = Drills.schedule(mode, seconds, order)
	level = clampi(difficulty, 1, 7)
	for stage: Dictionary in plan:
		duration += stage.seconds
	_next_stage()


func _next_stage() -> void:
	if stage_index >= 0:
		_credit_tracking(stage_duration)
		stages.append(metrics.snapshot(stage_mode, stage_duration))
		total.merge(metrics)
		if mode == "adaptive" and metrics.values.shots >= 3.0:
			var priority := TrainingMetrics.drill_priority(stages.back())
			if priority <= 0.32:
				level = mini(level + 1, 7)
			elif priority >= 0.62:
				level = maxi(level - 1, 1)
	stage_index += 1
	if stage_index == plan.size():
		finished = true
		return
	stage_mode = plan[stage_index].mode
	stage_duration = plan[stage_index].seconds
	stage_elapsed = 0.0
	metrics = TrainingMetrics.new()
	player = Vector3.ZERO
	previous_player = player
	velocity = Vector3.ZERO
	accurate = true
	cover = stage_mode == "peek"
	lane_start = player.x
	pending_at = 0.0
	shot_ready = 0.0
	peek_index = rng.randi_range(0, 3)
	motion = TrackingMotion.new()
	previous_velocity = Vector3.ZERO
	shown_speed = 0.0
	shown_time = 0.0
	last_track_time = 0.0
	track_aligned = false
	last_view = Vector2.ZERO
	shot_feedback = ""
	grid_reference = Vector2.ZERO
	for target: Target in targets:
		target.active = false
		target.expired_on_screen = false
		target.displayed = false
	var count := 6 if stage_mode == "grid" else (3 if stage_mode == "head" else 1)
	if stage_mode == "reaction":
		pending_at = _reaction_delay()
	elif stage_mode != "stop":
		for index in count:
			_spawn(index)


func step(move: Vector2, look: Vector2, delta: float = Drills.STEP) -> bool:
	if finished:
		return false
	elapsed = minf(duration, elapsed + delta)
	stage_elapsed += delta
	if stage_elapsed + 0.000001 >= stage_duration:
		_next_stage()
		if finished:
			elapsed = duration
		return true
	previous_player = player
	previous_velocity = velocity
	last_view = look
	if stage_mode == "stop" or stage_mode == "peek":
		var desired := Vector3(move.x, 0, move.y).rotated(Vector3.UP, look.x) * Drills.MOVE_SPEED
		var reversing := velocity.dot(desired) < 0.0
		if reversing:
			last_stop_kind = "reverse"
		elif desired.is_zero_approx() and velocity.length() > Drills.STOP_SPEED:
			last_stop_kind = "release"
		var brake := 52.0 if reversing else 38.0
		velocity = velocity.move_toward(desired, (brake if reversing or desired.is_zero_approx() else 33.0) * delta)
		player = RangeGeometry.move_player(player, velocity * delta, cover)
		accurate = velocity.length() <= Drills.STOP_SPEED
	if stage_mode in ["track", "reactive"]:
		var target := targets[0]
		target.previous = target.position
		var direction := motion.advance(rng, stage_mode == "reactive", level, delta)
		target.position = player + Vector3.UP * Drills.EYE_HEIGHT + direction * 7.8

	elif stage_mode == "stop":
		var target := targets[0]
		if target.active and stage_elapsed - target.born >= 2.8 - float(level) * 0.15:
			metrics.add("expired")
			target.expired_on_screen = target.displayed
			target.active = false
			lane_start = player.x
		elif not target.active and stage_elapsed >= pending_at and absf(player.x - lane_start) >= 0.87:
			_spawn(0)
	elif stage_mode == "reaction":
		var target := targets[0]
		if target.active and stage_elapsed - target.born >= _reaction_window():
			metrics.add("expired")
			target.expired_on_screen = target.displayed
			target.active = false
			pending_at = stage_elapsed + _reaction_delay()
		elif not target.active and stage_elapsed >= pending_at:
			_spawn(0)
	return false


func _reaction_delay() -> float:
	return rng.randf_range(0.7, 2.25)


func _reaction_window() -> float:
	return 1.42 - float(level) * 0.125


func _spawn(index: int) -> void:
	var target := targets[index]
	target.active = true
	target.visible = false
	target.displayed = false
	target.expired_on_screen = false
	target.seen_at = -1.0
	target.human = stage_mode in ["head", "peek", "stop"]
	target.born = stage_elapsed
	var scale := 1.0 - (level - 3) * 0.082
	match stage_mode:
		"grid", "head":
			var eye := player + Vector3.UP * Drills.EYE_HEIGHT
			target.base = SpawnLayout.point(rng, eye, last_view.x, targets, index, target.human)
			target.radius = 0.19 * scale
		"micro":
			var eye := player + Vector3.UP * Drills.EYE_HEIGHT
			var anchor := RangeGeometry.angles(eye, target.base) if stage_elapsed > 0.0 else last_view
			target.base = SpawnLayout.micro(rng, eye, anchor)
			target.radius = 0.10 * scale
		"track", "reactive":
			target.base = Vector3(0.0, 1.65, -7.8)
			target.radius = (0.20 if stage_mode == "track" else 0.27) * scale
		"stop":
			target.base = Vector3(clampf(player.x + rng.randf_range(-2.05, 2.05), -5.7, 5.7), 0.0, -8.4)
			target.radius = 0.25 * scale
		"peek":
			# Two inner positions require a wide swing. Outer positions require a new angle around a side block.
			var points := [Vector3(-1.40, 0, -10.3), Vector3(1.35, 0, -10.5), Vector3(-5.0, 0, -12.7), Vector3(5.0, 0, -13.9)]
			target.base = points[peek_index] + Vector3(rng.randf_range(-.58,.58),0,rng.randf_range(-.85,.45))
			target.base.z -= (level - 3) * 0.30
			peek_index = (peek_index + rng.randi_range(1, 3)) % points.size()
		"reaction":
			target.base = Vector3(rng.randf_range(-3.4, 3.4), rng.randf_range(0.96, 2.4), -8.5)
			target.radius = 0.28 * scale
	target.previous = target.base
	target.position = target.base
	target.presented = target.base
	if stage_mode != "peek":
		metrics.add("opportunities")


func present(alpha: float, look: Vector2, vertical: float, aspect: float, record: bool = true) -> void:
	shown_time = maxf(0.0, stage_elapsed - (1.0 - alpha) * Drills.STEP)
	if record:
		_credit_tracking(shown_time)
	shown_stop_kind = last_stop_kind
	shown_look = look
	shown_speed = previous_velocity.lerp(velocity, alpha).length()
	visible_eye = previous_player.lerp(player, alpha) + Vector3.UP * Drills.EYE_HEIGHT
	var forward := RangeGeometry.aim_direction(look)
	var right := Vector3(cos(look.x), 0, -sin(look.x))
	var up := right.cross(forward)
	var half_height := tan(deg_to_rad(vertical) / 2.0)
	for target: Target in targets:
		if not target.active:
			target.visible = false
			target.expired_on_screen = false
			target.displayed = false
			continue
		target.displayed = true
		target.presented = target.previous.lerp(target.position, alpha)
		if record and stage_mode in ["track", "reactive"]:
			track_aligned = RangeGeometry.sphere_distance(visible_eye, forward, target.presented, target.radius) < INF
		var point := target.point(true)
		var difference := point - visible_eye
		var depth := forward.dot(difference)
		target.visible = depth > 0.0 and absf(up.dot(difference)) <= depth * half_height and absf(right.dot(difference)) <= depth * half_height * aspect
		if not record or target.seen_at >= 0.0 or not target.visible or continuous_target or stage_mode in ["grid", "track", "reactive"]:
			continue
		var distance := difference.length()
		if RangeGeometry.obstruction(visible_eye, difference / distance, cover) < distance:
			continue
		target.seen_at = shown_time
		target.seen_look = look
		target.seen_eye = visible_eye
		if cover:
			metrics.add("opportunities")
			metrics.add("preaim_n")
			metrics.add("preaim_deg", rad_to_deg(RangeGeometry.angular_error(RangeGeometry.angles(visible_eye, point), look).length()))


func _credit_tracking(time: float) -> void:
	if stage_mode not in ["track", "reactive"]:
		return
	var dt := maxf(0.0, time - last_track_time)
	metrics.add("track_ticks", dt)
	if trigger_held and track_aligned:
		metrics.add("track_on", dt)
	last_track_time = maxf(last_track_time, time)

func can_shoot() -> bool:
	return not finished and stage_elapsed + 0.000001 >= shot_ready


func shoot(look: Vector2) -> int:
	# 0: blocked by cooldown, 1: miss, 2: body or sphere, 3: head.
	if not can_shoot():
		return 0
	shot_ready = stage_elapsed + (0.0833333 if stage_mode in ["track", "reactive"] else 0.1125)
	metrics.add("shots")
	var spread := 0.0
	if stage_mode == "stop" or cover:
		metrics.add("stop_shots")
		var movement := clampf((shown_speed - Drills.STOP_SPEED) / (Drills.MOVE_SPEED - Drills.STOP_SPEED), 0, 1)
		spread = deg_to_rad(movement * 6.0)
		if movement > 0:
			metrics.add("unsettled")
		else:
			metrics.add(shown_stop_kind)
	var shot := look
	if spread > 0.0:
		shot += Vector2.from_angle(spread_rng.randf_range(-PI, PI)) * (sqrt(spread_rng.randf()) * spread)
	var eye := visible_eye
	var ray := RangeGeometry.aim_direction(shot)
	var nearest := RangeGeometry.obstruction(eye, ray, cover)
	var hit_index := -1
	var hit_kind := 1
	var intent_index := -1
	var intent_distance := INF
	for index in targets.size():
		var target := targets[index]
		if not target.displayed or (not target.active and not target.expired_on_screen):
			continue
		var target_point := target.point(true)
		var distance := RangeGeometry.sphere_distance(eye, ray, target_point, RangeGeometry.HEAD_RADIUS if target.human else target.radius)
		if distance < nearest:
			nearest = distance
			hit_index = index
			hit_kind = 3 if target.human else 2
		if target.human:
			for part: Array in RangeGeometry.BODY:
				var center: Vector3 = target.presented + part[0]
				var size: Vector3 = part[1]
				distance = RangeGeometry.box_distance(eye, ray, AABB(center - size * 0.5, size))
				if distance < nearest:
					nearest = distance
					hit_index = index
					hit_kind = 2
		if target.visible:
			var difference := target_point - eye
			if cover and RangeGeometry.obstruction(eye, difference.normalized(), true) < difference.length():
				continue
			var error := RangeGeometry.angular_error(RangeGeometry.angles(eye, target_point), look).length_squared()
			if error < intent_distance:
				intent_distance = error
				intent_index = index
	if intent_index >= 0:
		_record_aim(targets[intent_index], eye, look)
	if stage_mode == "grid":
		grid_reference = look
	shot_feedback = "提前开枪" if (cover or stage_mode == "stop") and shown_speed > Drills.STOP_SPEED else ""
	if hit_index < 0:
		shot_feedback += " 空枪"
		return 1
	shot_feedback += " 爆头" if hit_kind == 3 else (" 身体命中" if targets[hit_index].human else " 命中")
	if hit_kind == 3 and (cover or stage_mode == "stop") and shown_speed <= Drills.STOP_SPEED:
		metrics.add("valid_heads")
	metrics.add("hits")
	if hit_kind == 3:
		metrics.add("heads")
	if (cover or stage_mode == "stop") and shown_speed > Drills.STOP_SPEED:
		return hit_kind
	if stage_mode in ["head", "peek", "stop"] and hit_kind != 3:
		return hit_kind
	var hit := targets[hit_index]
	if hit.expired_on_screen:
		metrics.add("expired", -1)
		hit.expired_on_screen = false
	hit.displayed = stage_mode in ["track", "reactive"] or continuous_target
	if hit.seen_at >= 0.0:
		metrics.add("reaction_n")
		metrics.add("reaction_ms", maxf(0.0, shown_time - hit.seen_at) * 1000.0)
	match stage_mode:
		"track", "reactive":
			pass
		"reaction":
			hit.active = false
			pending_at = stage_elapsed + _reaction_delay()
		"stop":
			hit.active = false
			lane_start = player.x
			pending_at = stage_elapsed + 0.28
		_:
			_spawn(hit_index)
	return hit_kind


func _record_aim(target: Target, eye: Vector3, look: Vector2) -> void:
	var point := target.point(true)
	var wanted := RangeGeometry.angles(eye, point)
	var end_error := RangeGeometry.angular_error(wanted, look)
	metrics.record_error(end_error)
	if cover or stage_mode in ["stop", "track"] or (target.seen_at < 0.0 and stage_mode != "grid"):
		return
	var start_error := RangeGeometry.angular_error(wanted, grid_reference) if stage_mode == "grid" else RangeGeometry.angular_error(RangeGeometry.angles(target.seen_eye, point), target.seen_look)
	var radius := RangeGeometry.HEAD_RADIUS if target.human else target.radius
	metrics.record_flick(start_error, end_error, atan2(radius, eye.distance_to(point)))


func report() -> Dictionary:
	var result := total.snapshot(mode, duration)
	result["stages"] = stages.duplicate(true)
	result["level"] = level
	result["seed"] = str(session_seed)
	result["rules"] = 3
	return result
