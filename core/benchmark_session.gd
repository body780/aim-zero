class_name BenchmarkSession
extends RangeSession

var spec: Dictionary
var heading: Array[float] = []
var turns: Array[float] = []
var vertical: Array[float] = []
var health: Array[int] = []
var magazine := 0
var reloading := false
var eliminations := 0
var waiting_until := 0.0
var drift: Array[Vector2] = []

func begin(selected_mode: String, seconds: int, difficulty: int, order: Array, seed_value: int = 0) -> void:
	spec = BenchmarkCatalog.ITEMS[selected_mode]
	for i in targets.size():
		heading.append(0)
		turns.append(0)
		vertical.append(0)
		health.append(0)
		drift.append(Vector2.ZERO)
	magazine = spec.mag
	super.begin(selected_mode, 1000 if spec.pattern == "ground" else seconds, difficulty, order, seed_value)
	player.z = -6.0
	previous_player = player
	for i in range(1, int(spec.count)):
		_spawn(i)

func automatic() -> bool:
	return spec.pattern in ["ground","orbit"] or spec.hp > 1

func _spawn(i: int) -> void:
	var t := targets[i]
	if t.active:
		if spec.pattern in ["ground","orbit"]:
			if spec.pattern == "ground":
				health[i] -= 1
				if health[i] == 0:
					t.active = false
					waiting_until = stage_elapsed + 1.5
					eliminations += 1
					metrics.add("eliminations")
			return
		health[i] -= 1
		if health[i] > 0:
			return
		eliminations += 1
		metrics.add("eliminations")
		magazine = spec.mag
	health[i] = int(spec.hp)
	t.active = true
	t.visible = false
	t.seen_at = -1
	drift[i] = Vector2.ZERO
	t.born = stage_elapsed
	t.radius = spec.radius
	for attempt in 24:
		var spread: float = spec.extent
		t.position = Vector3(rng.randf_range(-spread, spread), rng.randf_range(.65, 2.95), -12.0)
		if spec.pattern == "float":
			t.position.y = .65 + .67 * rng.randi_range(0,3)
		if spec.pattern in ["field","bounce"]:
			t.position.z += rng.randf_range(-1.6,1.6)
		if spec.pattern == "pair":
			t.position.y = 1.65 + rng.randf_range(-.52,.52)
		var clear := true
		for other: Target in targets:
			if other != t and other.active and Vector2(other.position.x-t.position.x,other.position.y-t.position.y).length() < t.radius*3.4:
				clear = false
		if clear: break
	t.base = t.position
	t.previous = t.position
	t.presented = t.position
	turns[i] = stage_elapsed
	vertical[i] = rng.randf_range(-.32,.32) if spec.pattern == "orbit" else rng.randf_range(.5,2.4)
	metrics.add("opportunities")

func step(move: Vector2, look: Vector2, delta: float = Drills.STEP) -> bool:
	if spec.pattern == "ground" and eliminations == 6:
		duration = elapsed + delta
		stage_duration = duration
	if super.step(move, look, delta): return true
	if reloading and stage_elapsed >= shot_ready:
		reloading = false
		magazine = spec.mag
	for i in int(spec.count):
		var t := targets[i]
		if not t.active:
			if stage_elapsed >= waiting_until: _spawn(i)
			continue
		t.previous = t.position
		var speed: float = spec.speed
		if speed == 0: continue
		var p: String = spec.pattern
		if stage_elapsed >= turns[i]:
			heading[i] = rng.randf_range(-PI,PI)
			var interval := rng.randf_range(.25,1.2)
			if p == "ground":
				interval *= [1.0,2.3,.85,.85,2.1,2.1][eliminations % 6]
			if p == "orbit":
				interval = rng.randf_range(.85,2.5)
			turns[i] = stage_elapsed + interval
		var age := stage_elapsed - t.born
		if p == "orbit":
			var radius := 3.8 + .78*sin(age*.74+t.base.y) + .34*sin(age*1.13+t.base.x)
			var target_speed := (speed/radius) * (1.0 if cos(heading[i]) >= 0 else -1.0)
			drift[i].x = move_toward(drift[i].x,target_speed,delta*1.2)
			vertical[i] += drift[i].x*delta
			var lift := .32*absf(sin(age*2.05 + t.base.y))
			t.position = Vector3(radius*sin(vertical[i]),1.55+.64*sin(age*.89+t.base.x)+lift,-6-radius*cos(vertical[i]))
		else:
			var desired := Vector2.from_angle(heading[i])*speed
			var acceleration := speed * (3.0 if p == "ground" else 14.0)
			drift[i] = drift[i].move_toward(desired,acceleration*delta)
			var dx := drift[i].x*delta
			var dy := drift[i].y*delta*.65
			t.position.x += dx
			if absf(t.position.x)>spec.extent:
				t.position.x = clampf(t.position.x,-spec.extent,spec.extent)
				heading[i] = PI-heading[i]
			if p == "bounce":
				vertical[i] -= 4.9*delta
				t.position.y += vertical[i]*delta
				if t.position.y < .52:
					t.position.y = .52
					vertical[i] = rng.randf_range(2.2,4.9)
			elif p=="ground":
				t.position.y = 1.05
				t.position.z = [-11.4,-11.4,-14.6,-9.4,-14.6,-9.4][eliminations % 6]
				if eliminations < 2: t.position.y += .35*sin(age*2.3)
			elif p == "float":
				t.position.y = t.base.y + .22*sin(age*1.7+i)
			else:
				t.position.y += dy
				if t.position.y < .45 or t.position.y > 3.5:
					t.position.y = clampf(t.position.y,.45,3.5)
					heading[i] = -heading[i]
			if p == "bounce":
				t.position.z = t.base.z + .85*sin(age*1.5 + t.base.x)
			if p == "float":
				t.position.z = t.base.z + sin(age*speed*.6+t.base.x)*1.25
	return false

func shoot(look: Vector2) -> int:
	if reloading: return 0
	var before := eliminations
	var shot_ready_before := shot_ready
	var outcome := super.shoot(look)
	if outcome == 0: return 0
	var period := .01 if spec.pattern == "ground" else (.05 if automatic() else .10)
	shot_ready = maxf(stage_elapsed + period - Drills.STEP, shot_ready_before + period) if automatic() else stage_elapsed + period
	if spec.mag > 0 and before == eliminations:
		magazine -= 1
		if magazine <= 0:
			shot_ready = stage_elapsed + .5
			reloading = true
	if outcome == 2 and spec.pattern == "float":
		metrics.add("heads")
		return 3
	return outcome
