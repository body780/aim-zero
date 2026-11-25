class_name BenchmarkSession
extends RangeSession

const DEPTH := 8.0
var spec: Dictionary
var headings := PackedFloat64Array()
var next_turn := PackedFloat64Array()
var speeds := PackedVector3Array()
var desired := Vector3.ZERO
var magazine := 0
var reloading := false
var trigger_held := false
var bearing := 0.0
var radial_distance := 4.4
var elevation := 0.0
var jump_phase := 0.0
var last_spawn := Vector3.INF

func begin(selected_mode: String, _seconds: int, difficulty: int, order: Array, seed_value: int = 0) -> void:
	spec = BenchmarkCatalog.ITEMS[selected_mode]
	headings.resize(spec.count)
	next_turn.resize(spec.count)
	speeds.resize(spec.count)
	magazine = spec.mag
	continuous_target = automatic()
	super.begin(selected_mode,60,difficulty,order,seed_value)
	player.z = -6
	previous_player = player
	for i in range(1,int(spec.count)):
		_spawn(i)

func automatic() -> bool:
	return spec.mag == 0

func _spawn(i: int) -> void:
	var t := targets[i]
	if t.active:
		if automatic(): return
		metrics.add("eliminations")
		magazine = spec.mag
		last_spawn = t.position
	var eye := Vector3(0,Drills.EYE_HEIGHT,-6)
	var pos := eye
	match spec.pattern:
		"wall": pos += _sample_wall(i,3.9,1.40)
		"pair": pos += _sample_wall(i,.79,.47)
		"pasu":
			pos += _sample_wall(i,3.55,1.22)
			headings[i] = rng.randf_range(-PI,PI)
			speeds[i] = Vector3(cos(headings[i]),sin(headings[i]),0)*1.25
		"reactive":
			pos += Vector3(rng.randf_range(-1.4,1.4),rng.randf_range(-.65,.65),-5.2)
		"smooth":
			bearing = rng.randf_range(-.32,.32)
			pos += Vector3(radial_distance*sin(bearing),0,-radial_distance*cos(bearing))
	next_turn[i] = stage_elapsed
	t.radius = spec.radius
	t.active = true
	t.visible = false
	t.seen_at = -1
	t.born = stage_elapsed
	t.base = pos
	t.position = pos
	t.previous = pos
	t.presented = pos
	metrics.add("opportunities")

func _sample_wall(i: int, half_width: float, half_height: float) -> Vector3:
	var point := Vector3.ZERO
	for attempt in 64:
		point = Vector3(rng.randf_range(-half_width,half_width),rng.randf_range(-half_height,half_height),-DEPTH)
		var world := point + Vector3(0,Drills.EYE_HEIGHT,-6)
		var clear: bool = world.distance_to(last_spawn) > spec.radius*4
		for j in int(spec.count):
			if j != i and targets[j].active and world.distance_to(targets[j].position) < spec.radius*4:
				clear = false
		if clear: break
	return point

func step(move: Vector2, look: Vector2, delta: float = Drills.STEP) -> bool:
	if super.step(move,look,delta): return true
	if reloading and stage_elapsed + .000001 >= shot_ready:
		magazine = spec.mag
		reloading = false
	for i in int(spec.count):
		var t := targets[i]
		t.previous = t.position
		match spec.pattern:
			"pasu": _pasu(i,t,delta)
			"reactive": _reactive(t,delta)
			"smooth": _smooth(t,delta)
	if automatic():
		metrics.add("track_ticks",delta)
		if trigger_held and RangeGeometry.sphere_distance(player+Vector3.UP*Drills.EYE_HEIGHT,RangeGeometry.aim_direction(look),targets[0].position,targets[0].radius) < INF:
			metrics.add("track_on",delta)
	return false

func _pasu(i: int,t: Target,dt: float) -> void:
	if stage_elapsed >= next_turn[i]:
		headings[i] += rng.randf_range(.55,2.5)*(-1 if rng.randi()%2 else 1)
		next_turn[i] = stage_elapsed+rng.randf_range(.31,.95)
	var heading := Vector3(cos(headings[i]),sin(headings[i])*.78,0)
	var v := speeds[i].move_toward(heading*1.65,dt*12)
	var p := t.position+v*dt
	if absf(p.x)>3.85:
		p.x = clampf(p.x,-3.85,3.85)
		headings[i] = PI-headings[i]
		v.x = -v.x
	if p.y < .35 or p.y > 3.45:
		p.y = clampf(p.y,.35,3.45)
		headings[i] = -headings[i]
		v.y = -v.y
	speeds[i] = v
	t.position = p

func _reactive(t: Target,dt: float) -> void:
	if stage_elapsed >= next_turn[0]:
		var sign_x := -1 if desired.x > 0 else 1
		if rng.randf()<.19: sign_x *= -1
		desired = Vector3(sign_x*rng.randf_range(1.45,3.45),rng.randf_range(-1.4,1.4),rng.randf_range(-.8,.8))
		next_turn[0] = stage_elapsed+rng.randf_range(.14,.66)
	var p := t.position
	if absf(p.x)>3.1: desired.x = -signf(p.x)*absf(desired.x)
	if p.y<.65 or p.y>2.95: desired.y = signf(1.65-p.y)*maxf(.65,absf(desired.y))
	if p.z < -12.3 or p.z > -10: desired.z = signf(-11.1-p.z)*maxf(.45,absf(desired.z))
	speeds[0] = speeds[0].move_toward(desired,dt*27)
	t.position += speeds[0]*dt

func _smooth(t: Target,dt: float) -> void:
	if stage_elapsed >= next_turn[0]:
		desired = Vector3(rng.randf_range(.38,.77)*(-1 if rng.randi()%2 else 1),rng.randf_range(-.24,.24),rng.randf_range(-.65,.65))
		next_turn[0] = stage_elapsed+rng.randf_range(.8,2.3)
	if radial_distance>5.1 or radial_distance<3.8: desired.z = signf(4.4-radial_distance)*.44
	if absf(elevation)>.57: desired.y = -signf(elevation)*.17
	speeds[0] = speeds[0].move_toward(desired,dt*.7)
	bearing += speeds[0].x*dt
	elevation += speeds[0].y*dt
	radial_distance += speeds[0].z*dt
	jump_phase += dt*(2.1+absf(speeds[0].x))
	t.position = Vector3(sin(bearing)*radial_distance,Drills.EYE_HEIGHT+elevation+.09*(1.0-cos(2.0*jump_phase)),-6-cos(bearing)*radial_distance)

func shoot(look: Vector2) -> int:
	if reloading: return 0
	var prior := shot_ready
	var result := super.shoot(look)
	if result == 0: return 0
	if automatic():
		shot_ready = maxf(stage_elapsed+.05-Drills.STEP,prior+.05)
	else:
		shot_ready = stage_elapsed+.1
		if result == 1:
			magazine -= 1
			if magazine == 0:
				reloading = true
				shot_ready = stage_elapsed+.5
	return result
